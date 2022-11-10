provider "kubernetes" {
  config_path = "./kubeconfig"
  ignore_annotations = [
    "cni\\.projectcalico\\.org\\/podIP",
    "cni\\.projectcalico\\.org\\/podIPs",
  ]
}
