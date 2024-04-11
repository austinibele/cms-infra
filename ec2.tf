
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"

  ami                         = "ami-08018df724ef9440c"
  name                        = "CMS-EC2"
  associate_public_ip_address = true
  instance_type               = "t2.small"
  vpc_security_group_ids      = [module.ec2_security_group.this_security_group_id]
  subnet_ids                  = module.vpc.public_subnets
  key_name                    = aws_key_pair.generated_key.key_name

  tags = {
    Name = "CMS"
  }
}

# -------------------------------------------------------------------------------
# Key-Pair
# -------------------------------------------------------------------------------

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-ssh-keypair"
  public_key = tls_private_key.example.public_key_openssh
}


resource "local_sensitive_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/generated-key.pem"
}

# -------------------------------------------------------------------------------
# Security Group
# -------------------------------------------------------------------------------

module "ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.1.0"

  name   = "CMS-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access from my IP"
      cidr_blocks = "24.88.41.67/32"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

module "ec2_connect_role_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.7.0"

  role_name               = "CMS-rds-ec2-connect-role"
  role_requires_mfa       = false
  create_role             = true
  create_instance_profile = true

  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    aws_iam_policy.ec2_s3_access_policy.arn
  ]
}

locals {
  bucket_name = "myvisausa-public-images-bucket"
}

resource "aws_iam_policy" "ec2_s3_access_policy" {
  name        = "EC2S3AccessPolicy"
  description = "Policy allowing EC2 instance access to S3 bucket"

  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "arn:aws:s3:::${local.bucket_name}"
          ]
        }
      ]
    }
  EOF
}
