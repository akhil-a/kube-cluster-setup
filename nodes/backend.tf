terraform {
  backend "s3" {
    bucket = "terraform-statefiles-akhil10anil"
    key    = "kube-cluster-setup/terraform.tfstate"
    region = "ap-south-1"
  }
}
