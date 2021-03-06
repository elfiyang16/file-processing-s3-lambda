locals {
  static_bucket_name  = "${var.name_base}-static"
  upload_bucket_name  = "${var.name_base}-uploads"
  archive_bucket_name = "${var.name_base}-archive"
}

resource "aws_s3_bucket" "upload_bucket" {
  bucket = local.upload_bucket_name
  acl    = "private"

  cors_rule {
    allowed_headers = ["*", ]
    allowed_methods = ["PUT", "POST", ]
    allowed_origins = ["*", ]
    expose_headers  = ["ETag", ]
  }

  force_destroy = true
}

resource "aws_s3_bucket" "archive_bucket" {
  bucket = local.archive_bucket_name
  acl    = "private"

  force_destroy = true
}

resource "aws_s3_bucket" "static_bucket" {
  bucket = local.static_bucket_name
  acl    = "private"

  force_destroy = true
}

resource "aws_s3_bucket_object" "static_item" {
  for_each = {
    "index.html"        = "text/html; charset=utf-8"
    "favicon.ico"       = "image/x-icon"
    "js/credentials.js" = "text/javascript"
    "js/presign.js"     = "text/javascript"
  }
  bucket       = aws_s3_bucket.static_bucket.id
  key          = each.key
  source       = "${path.module}/../static/${each.key}"
  acl          = "public-read"
  content_type = each.value
  #  use the object etag to let Terraform recognize when the content has changed
  etag = filemd5("${path.module}/../static/${each.key}")
}
