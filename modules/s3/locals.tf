locals {
  bucket_name_parsed = replace(lower(var.bucket_name), " ", "-")

  _ap_suffix         = "-${var.access_point_name_suffix}"
  _ap_max_prefix_len = 50 - length(local._ap_suffix)
  access_point_name  = "${substr(local.bucket_name_parsed, 0, local._ap_max_prefix_len)}${local._ap_suffix}"
}
