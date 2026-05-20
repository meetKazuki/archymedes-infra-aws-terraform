variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket. Must be globally unique. Lowercased and spaces replaced with '-'."

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "bucket_name must be between 3 and 63 characters."
  }
}

variable "access_point_name_suffix" {
  type        = string
  description = "Suffix appended to the bucket name for the access point. Access point names are limited to 50 chars total."
  default     = "ap"
}
