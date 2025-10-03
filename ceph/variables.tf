# Variables
variable "keypair" {
  type    = string
  default = "dp"   # name of keypair created
}



variable "availability-zone" {
  type    = string
  default = "nova"
}

variable "network" {
  type    = string
  default = "test" # default network to be used
}

variable "security_groups" {
  type    = list(string)
  default = ["default"]  # Name of default security group
}

variable "mon_count" {
  type    = number
  default = 3
}


variable "app_cred_secret"{

type = string


}


