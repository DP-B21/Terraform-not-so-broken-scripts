# Data sources
## Get Image ID
data "openstack_images_image_v2" "image" {
  name        = "ubuntu-jammy" # Name of image to be used
  most_recent = true
}

data "openstack_compute_flavor_v2" "adm" {
  name = "large" # flavor to be used for jump
}

data "openstack_compute_flavor_v2" "mon-flavor" {
  name = "medium" # flavor to be used for mon nodes
}


resource "tls_private_key" "p_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "private_key" {
  value     = tls_private_key.p_key.private_key_pem
  sensitive = true
}

resource "openstack_compute_instance_v2" "adm" {
  name            = "adm"  #Instance name
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.adm.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["default"]

    # provisioner "remote-exec" {
   # connection {
     # type        = "ssh"
    #  user        = "ubuntu"
   #   private_key = tls_private_key.p_key.private_key_pem
  #    host        = self.access_ip_v4
 #     #timeout 	  = "10m"
#    }

#    inline = [
#      "echo 'adm instance is ready!'"
#    ]
#  }

    block_device {
    uuid                  = data.openstack_images_image_v2.image.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size = 100
    delete_on_termination = true
  }


  network {
    name = var.network
  }

  # Initial setup script for admin node
  user_data = <<-EOF
    #!/bin/bash
    echo "${tls_private_key.p_key.public_key_openssh}" >> /home/ubuntu/.ssh/authorized_keys
    apt-get update
    apt-get install -y python3-pip
    pip3 install ceph-deploy
    mkdir -p /etc/ceph
    mkdir -p /home/ubuntu/ceph-cluster
    chown ubuntu:ubuntu /home/ubuntu/ceph-cluster
  EOF


}


resource "openstack_compute_instance_v2" "mon" {
  name            = "mon${(count.index+1)}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.mon-flavor.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["default"]
  count           = var.mon_count
  

    block_device {
    uuid                  = data.openstack_images_image_v2.image.id 
    source_type           = "image"
    destination_type      = "volume"
    volume_size = 100
    delete_on_termination = true
  }

  network {
    name = var.network
  }
  

   connection {
    type 	= "ssh"
    host        = self.access_ip_v4
    user        = "ubuntu"
    private_key = tls_private_key.p_key.private_key_pem
    #timeou = "10m"
  } 



  timeouts{
	create = "30m"

}


user_data = <<-EOF
  #!/bin/bash
  set -e
  
  # Create .ssh directory if it doesn't exist
  mkdir -p /home/ubuntu/.ssh
  
  # Add the SSH key
  echo "${tls_private_key.p_key.public_key_openssh}" >> /home/ubuntu/.ssh/authorized_keys
  
  # Set correct permissions
  chmod 700 /home/ubuntu/.ssh
  chmod 600 /home/ubuntu/.ssh/authorized_keys
  chown -R ubuntu:ubuntu /home/ubuntu/.ssh
  
  # Update and install packages
  apt-get update
  apt-get install -y ntp python3
  
  # Create Ceph directories
  mkdir -p /var/lib/ceph
  mkdir -p /var/log/ceph
  mkdir -p /etc/ceph
  
  # Set proper permissions for Ceph directories if needed
  # chown ceph:ceph /var/lib/ceph /var/log/ceph /etc/ceph
EOF



  # Initial setup script for mon nodes
 # user_data = <<-EOF
    #!/bin/bash
  #  echo "${tls_private_key.p_key.public_key_openssh}" >> /home/ubuntu/.ssh/authorized_keys
  #  apt-get update
  #  apt-get install -y ntp python3
  #  mkdir -p /var/lib/ceph
  #  mkdir -p /var/log/ceph
  #  mkdir -p /etc/ceph
  #EOF
}

#resource "openstack_compute_instance_v2" "store" {
#  name            = "store"  #Instance name
#  image_id        = data.openstack_images_image_v2.image.id
#  flavor_id       = data.openstack_compute_flavor_v2.store.id
#  key_pair        = var.keypair
#  availability_zone_hints = var.availability-zone
#  security_groups = ["default"]
#
#  network {
#    name = var.network
#  }
#}

        resource "openstack_compute_floatingip_associate_v2" "jump" {
                floating_ip = openstack_networking_floatingip_v2.adm.address
                instance_id = openstack_compute_instance_v2.adm.id
		depends_on  = [openstack_compute_instance_v2.adm]
}


        resource "openstack_networking_floatingip_v2" "adm" {
                pool = "external"
}


resource "openstack_compute_volume_attach_v2" "mon_vol_attach" {  
  count       = var.mon_count
  instance_id = openstack_compute_instance_v2.mon[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.mon-vol[count.index].id
}




resource "openstack_blockstorage_volume_v3" "adm_vol" {
  name        = "adm_vol"
  size        = 100  # Size in GB
  description = "Volume for adm instance"
}


resource "openstack_blockstorage_volume_v3" "mon-vol" {
  name = "mon-vol${(count.index+1)}"
  size = 100
  count= var.mon_count
  volume_type="ceph-ssd"
}


# Output adm host floating IP Address
output "jumpserverfloatingip" {
 value = openstack_networking_floatingip_v2.adm.address
} 
