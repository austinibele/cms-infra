# IMPORTANT: Needed to set "Block all public access" to FALSE in AWS S3 Console
resource "aws_s3_bucket" "public_images" {
  bucket_prefix = "myvisausa-public-images-bucket"

  tags = {
    Name = "PublicImages"
  }
}

resource "aws_s3_bucket_policy" "combined_policy" {
  bucket = aws_s3_bucket.public_images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["s3:GetObject"],
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.public_images.arn}/*"
        Principal = "*"
      },
      {
        Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.public_images.arn}/*"
        Principal = {
          "AWS": "arn:aws:iam::349514606126:root"
        }
      },
    ]
  })
}