variable "cloudflare_tunnel_cred_file_name" {
  type        = string
  description = "File name of the cloudflared tunnel credentials file"
}

variable "domain_name" {
  type        = string
  description = "Domain name you have configured for your cloudflared tunnel "
}
