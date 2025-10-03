resource "tls_private_key" "p_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

data "openstack_images_image_v2" "image" {
  name        = "ubuntu-jammy" # Name of image to be used
  most_recent = true
}


resource "openstack_compute_keypair_v2" "deployer" {
  name = "deployer-key"
  public_key = file("~/.ssh/keys/somerville-openstack.pub")
}

resource "openstack_compute_instance_v2" "vm1" {
  name = "vm1"
  image_name = "ubuntu-jammy"
  flavor_name = "qserv-worker"
  key_pair = openstack_compute_keypair_v2.deployer.name
  security_groups = ["test"]
  network {
    name = "test"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("/home/master/.ssh/keys/somerville-openstack")
    host = self.access_ip_v4
  }




}


resource "openstack_blockstorage_volume_v3" "vm1_volume" {
  name = "vm1_volume"
  size = 100
  image_id = data.openstack_images_image_v2.image.id
}





resource "openstack_compute_instance_v2" "vm2" {
  name = "vm2"
  image_name = "ubuntu-jammy"
  flavor_name = "qserv-worker"
  key_pair = openstack_compute_keypair_v2.deployer.name
  security_groups = ["test"]
  network {
    name = "test"
  }
  provisioner "remote-exec" {
    inline = [
      "ssh -o StrictHostKeyChecking=no ubuntu@${openstack_compute_instance_v2.vm1.access_ip_v4} 'echo Hello from VM2'"
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("/home/master/.ssh/keys/somerville-openstack")
      host = self.access_ip_v4
    }



  }
}


resource "openstack_blockstorage_volume_v3" "vm2_volume" {
  name = "vm1_volume"
  size = 100
  image_id = data.openstack_images_image_v2.image.id
}


resource "openstack_compute_volume_attach_v2" "vm1_vol_attach"{

instance_id = openstack_compute_instance_v2.vm1.id
volume_id = openstack_blockstorage_volume_v3.vm1_volume.id

}


resource "openstack_compute_volume_attach_v2" "vm2_vol_attach"{

instance_id = openstack_compute_instance_v2.vm2.id
volume_id = openstack_blockstorage_volume_v3.vm2_volume.id

}







output "vm1_ip" {
  value = openstack_compute_instance_v2.vm1.access_ip_v4
}

output "vm2_ip" {
  value = openstack_compute_instance_v2.vm2.access_ip_v4
}

