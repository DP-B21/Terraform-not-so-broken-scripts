#point to config file
data "template_file" "cloud-init-test"{

	template = "${file("${path.module}/cloud_init_test.cloud_config")}"

}  


#create a file  
resource "local_file" "cloud-init-test"{

content = data.template_file.cloud-init-test.rendered
filename = "${path.module}/cloud_init_test_conf.cfg"

}  



# Transfer the file to the Proxmox Host

resource "null_resource" "cloud-init-test" {

    connection {

	script_path = "${path.module}/winconfig.ps1"
	type = "ssh"
	user = "dp"
	password = "123"
	host = "172.24.12.134"
  private_key = file("~/.ssh/id_rsa")

}




 }
  
resource "proxmox_vm_qemu" "test4" {
  
  

  depends_on = [

    null_resource.cloud-init-test


  ]

  provisioner "file" {

    source = "local_file.cloud-init-test_vm-01.filename"
    destination  = "/var/lib/vz/snippets/cloud-init-test.yml"
  }

  name = "cloudinit3"
  desc = "DPWSSH"
  
  target_node = "stitchy-dell-1"
  #count = 5

  #content= data.template_file.cloud-init-test.rendered
  agent = 1
  onboot = true
  bootdisk = "scsi0"
  
  
  #vmid = 600
  boot= "order=virtio1;"
  clone = "DPWINFINAL"
  cores = 16
  sockets = 1
  cpu = "host"
 
  memory = 4096

  network {

    bridge = "vmbr1"
    model = "virtio"

  }
  disk{

   storage = "ceph_for_vms"
    type = "virtio"
    size = "64G"
	cache = "writeback"
  } 
  
#boot_disk{
#	initialize_params{


#		image = " "
  


#}
#}



os_type = "cloud-init"
cicustom = "user=local:snippets/cloud-init-test.yml"
#sshkeys = ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCw/K5PGiStnI+4rpNHLjB5J61GWAmCKQpBNxVuj+QqNzfeR0GfGchS/PebJIqNs/4wl0JlufbOCKKrGTaRYB6Mw1/4cHcN7ENv8UNG8OfhDxjrz5ehFX10WLGm/puktvYuEhnFlyYUIKLnMHZ4fHBa77glSV9aLQDvsisCEz/wFXMSJuufUxonTVPbqxbPFP4dB4qPMkqsLSfMhlIgsR4NqHuqaePwV73+f0oOQU4wNQyItu0CAhed4UNp3sMkfFMNIOp0y0XK15fR3nsA1Lp8Wzg2VGOQJE7G7+5/ACoDJtOOzdqd2YRXrePLE7jcpoUsh4Y8dK07CWD2Fr9rwu8FM9DlBgLf9e1WVMw2QznImoNz9oGSxfjwpBjlE1jhjH/5zNotWKaEQTme7STiKJdDVdCenwTcCa0nZ82cg4PK2xFdNm8A8PN2Evm0qxculr09aAvL5HOAu9vLvzHm2QC0r+PUedDwUkRJZWEwFguLRVY0zQGKYE8zvkHoJ7EgKds= dpizarro@ed.ac.uk


}













