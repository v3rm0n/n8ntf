variable "cloudflare_tunnel_creds" {
  type        = string
  description = "Cloudflared tunnel credentials json"
}

variable "domain_name" {
  type        = string
  description = "Domain name you have configured for your cloudflared tunnel "
}
