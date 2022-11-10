# n8n on Kubernetes in Terraform

Deploys [n8n](https://n8n.io) to a Kubernetes cluster using [Terraform](https://www.terraform.io). Exposes the endpoint using [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/).

## Prerequisites
- CloudFlare account
  - Tunnel created using `cloudflared tunnel create n8n`
  - Credentials file saved to the project root
  - Credentials file name provided as a Terraform variable
  - Domain name set up for the tunnel `cloudflared tunnel route dns tunnelId domainName`
  - Domain name provided as a Terraform variable
- Kubernetes cluster set up
- Terraform installed
- Correct `kubeconfig` location in *provider.tf*

## Usage
- Use `terraform apply` to deploy and `terraform destroy` to delete the resources.
