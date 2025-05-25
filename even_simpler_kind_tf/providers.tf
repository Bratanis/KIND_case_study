terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.9.0" # 0.9.0
    }
  }
}

provider "kind" {}
