variable "resource_group_name" {
  description = "Resource group for the cost-conscious hybrid landing zone lab."
  type        = string
  default     = "rg-lab-hybrid-landingzone-tf"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "southafricanorth"
}

variable "tags" {
  description = "Tags applied to lab resources."
  type        = map(string)
  default = {
    Lab         = "Hybrid-Landing-Zone"
    Environment = "Practice"
    CostModel   = "Cost-Conscious"
    Owner       = "Julian"
  }
}
