# Add this after your existing resources

# Wait for instances to be fully ready
resource "null_resource" "wait_for_instances" {
  depends_on = [
    openstack_compute_instance_v2.adm,
    openstack_compute_instance_v2.mon,
    openstack_compute_volume_attach_v2.mon_vol_attach
  ]

  # Give some time for cloud-init to complete
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

# Configure Ceph adm node and initialize cluster
resource "null_resource" "ceph_setup" {
  depends_on = [null_resource.wait_for_instances]

  # Use the adm node's floating IP to SSH
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.p_key.private_key_pem
    host        = openstack_networking_floatingip_v2.adm.address
    agent = true
  }

  # Set up SSH config and keys for passwordless access
  provisioner "remote-exec" {
  inline = [
      # Get private IPs for each mon node

      "MON0_IP=${openstack_compute_instance_v2.mon[0].access_ip_v4}",
      "MON1_IP=${openstack_compute_instance_v2.mon[1].access_ip_v4}",
      "MON2_IP=${openstack_compute_instance_v2.mon[2].access_ip_v4}",
      "IP_ADDRESS=$(hostname -I | awk '{print $1}')",

      #Python install
      "sudo apt-get update",
      "sleep 30",
      "sudo apt-get install -y python3",
      "sleep 30",
      "sudo apt-get install -y python3-pip",
      " sleep 30",
      " sleep 20",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev libc6-dev",
      "sleep 60",
      "wget https://www.python.org/ftp/python/3.6.15/Python-3.6.15.tgz",
      "sleep 60",
      "tar -xzf Python-3.6.15.tgz",
      "./Python-3.6.15/configure/--enable-optimizations  -with-lto  --with-pydebug",
      "sudo make altinstall",

      #podman setup
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install podman",

      #Ceph setup
      "pip3 install git+https://github.com/ceph/ceph-deploy.git",
      "sudo DEBIAN_FRONTEND=noninteractive apt install ceph-common -y",
      "sudo ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'",
      "sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'",
      "sudo ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring",
      "sudo pip3 install ceph-deploy -y",
      "sudo ceph-deploy new adm",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y cephadm",
      "sudo cephadm add-repo --release 19.2.1",
      "sudo DEBIAN_FRONTEND=noninteractive cephadm install",
      "sudo rm -rf /etc/ceph/*",
      "sudo rm -rf /var/lib/ceph/*",
      "sudo cephadm bootstrap --mon-ip $IP_ADDRESS --allow-fqdn-hostname",
      "sleep 30",
      "sudo ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@$MON0_IP -o StrictHostKeyChecking=no",
      "sudo ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@$MON1_IP -o StrictHostKeyChecking=no",
      "sudo ssh-copy-id -f -i /etc/ceph/ceph.pub ubuntu@$MON2_IP -o StrictHostKeyChecking=no",
      "sleep 30",
      "sudo ceph orch host add mon0 $MON1_IP",
      "sleep 30",
      "sudo ceph orch host add mon1 $MON1_IP",
      "sleep 30 ",
      "sudo ceph orch host add mon2 $MON2_IP",
      "sudo cephadm add-repo --release squid",
      "sudo DEBIAN_FRONTEND=noninteractive cephadm install ceph-common",
      "sudo ceph orch apply mon mon1,mon2",
      "sudo ceph status",
    ]
  }
}

# Test the Ceph cluster
resource "null_resource" "ceph_test" {
  depends_on = [null_resource.ceph_setup]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.p_key.private_key_pem
    host        = openstack_networking_floatingip_v2.adm.address
    agent = true
  }

#
#provisioner "remote-exec" {
#    inline = [
#      # Check cluster status
#      "sudo ceph -s",
#      
#      # Create a test pool
#      "sudo ceph osd pool create test-pool 32 32",
#      
#      # Create a test file and put it in the pool
#      "echo 'This is a test file for Ceph' > test-file",
#      "sudo rados -p test-pool put test-object test-file",
#      
#      # Retrieve the test file to verify
#      "sudo rados -p test-pool get test-object retrieved-file",
#      "cat retrieved-file",
#      
#      # Check object placement
#      "sudo ceph osd map test-pool test-object",
#      
#      # Run a quick performance test
#      "sudo rados bench -p test-pool 10 write --no-cleanup",
#      "sudo rados bench -p test-pool 10 seq",
#      
#      # Clean up the test data
#      "sudo rados -p test-pool cleanup",
#      "sudo ceph osd pool delete test-pool test-pool --yes-i-really-really-mean-it",
#      
#      # Output final cluster status
#      "sudo ceph -s"
#    ]
#  }
}
#

resource "null_resource" "copy_ceph_keys" {
  count      = var.mon_count
  depends_on = [null_resource.ceph_setup]

  provisioner "remote-exec" {
    connection {
      host        = openstack_networking_floatingip_v2.adm.address
      user        = "ubuntu"
      private_key = tls_private_key.p_key.private_key_pem
    }

    inline = [
      "scp -o StrictHostKeyChecking=no /etc/ceph/ceph.client.admin.keyring ubuntu@${openstack_compute_instance_v2.mon[count.index].access_ip_v4}:/tmp/",
      "scp -o StrictHostKeyChecking=no /etc/ceph/ceph.mon.keyring ubuntu@${openstack_compute_instance_v2.mon[count.index].access_ip_v4}:/tmp/"
    ]
  }
}

# Move the keys to the right location on MON nodes
resource "null_resource" "setup_mon_keys" {
  count      = var.mon_count
  depends_on = [null_resource.copy_ceph_keys]

  provisioner "remote-exec" {
    connection {
      host        =  openstack_compute_instance_v2.mon[count.index].access_ip_v4 
      user        = "ubuntu"
      private_key = tls_private_key.p_key.private_key_pem
    }

    inline = [
      "sudo mv /tmp/ceph.client.admin.keyring /etc/ceph/",
      "sudo mv /tmp/ceph.mon.keyring /etc/ceph/",
      "sudo chmod 640 /etc/ceph/ceph.client.admin.keyring",
      "sudo chmod 640 /etc/ceph/ceph.mon.keyring",
      "sudo chown ceph:ceph /etc/ceph/ceph.client.admin.keyring",
      "sudo chown ceph:ceph /etc/ceph/ceph.mon.keyring"
    ]
  }
}


# Add new outputs to show test results
#output "ceph_setup_complete" {
#  value = "Ceph cluster setup and testing complete. SSH to ${openstack_networking_floatingip_v2.adm.address} to access the adm node."
#}
