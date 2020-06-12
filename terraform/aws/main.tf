provider "aws" {
    region = var.aws_region
    version = "~> 2.64"
}

locals {
  //Put all common tags here
  common_tags = {
    Project = "Startup Sample"
    Environment = "Development"    
  
  }

  dns_domain_extract = regex("^(?P<domain>(?P<domain_sub>(?:[^\\/\\\"\\]:\\.\\s\\|\\-][^\\/\\\"\\]:\\.\\s\\|]*?\\.)*?)(?P<domain_root>[^\\/\\\"\\]:\\s\\.\\|\\n]+\\.(?P<domain_tld>(?:xn--)?[\\w-]{2,7}(?:\\.[a-zA-Z-]{2,3})*)))$", var.cert_ssl_domain)

  use_ssl = var.cert_ssl_domain != "" ? true : false

}
