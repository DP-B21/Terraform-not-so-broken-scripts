resource "openstack_compute_instance_v2" "server" {


count = 1
name ="S_TEST"

#clone = "DP"

image_id = "afd21f97-b066-4edd-80f4-ac7aa300bc1b"
security_groups = ["default"]
flavor_id = "670aef98-5ee4-4dbf-9000-48472430426b"
key_pair = "dp"
 


network{

uuid = "31d00f46-e1cb-41a8-a935-52f33be309ce"



}









#provisioner "local-exec"{

#working_dir = "/home/master/Somerville"
#command = "echo ${self.access_ip_v4} > ip.txt"


#}


#data "template_file" "user_data" {
 # template = file("/home/master/Somerville/scripts/add-ssh-web-app.yaml")
#}


}



resource "openstack_networking_floatingip_v2" "floating_ip"{

pool = "external"


}


resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  floating_ip = openstack_networking_floatingip_v2.floating_ip.address
  instance_id  = openstack_compute_instance_v2.floating_ip.id
}



#resource "openstack_compute_volume_attach_v2" "attach_1" {
#  instance_id = "86b1b48c-c5f8-426f-bae6-9d971f1f8378"
#  volume_id   = "fa5611eb-8d5c-4981-8efb-e272bf89ef9b"
#}

