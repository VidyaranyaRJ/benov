terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}


################################# ACM Route53 #################################

module "acm_route53" {
  source                   = "../../resources/ACM_Route53"
  route53_zone_id          = "Z1008022QVBNCVSQ3P61"
  acm_certificate_tag_name = "benevolate-cert"
  route53_record_ttl       = 60
  domain_name              = "benevolaite.com"
}
