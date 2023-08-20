variable "hcloud_token" {
  description = "token for hcloud api access"
  type        = string
  sensitive   = true # Requires terraform >= 0.14
}
