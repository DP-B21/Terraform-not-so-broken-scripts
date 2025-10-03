terraform {
	required_version = ">= 0.14.0"
		required_providers {
			openstack = {
					source = "terraform-provider-openstack/openstack"
					version = " ~> 1.48.0"


				}
			}	
		}

variable "api_key"{


type = string 
sensitive = true
}

#auth_type="token"
provider "openstack" {
key = var.api_key
cloud = "openstack"
auth_url = "https://somerville.ed.ac.uk:5000"
user_name = "dpizarro"
tenant_name = "test"
application_credential_secret = var.app_cred_secret

application_credential_id= "8854bfc5250c4d5ca2d0556904f4d148"

}


