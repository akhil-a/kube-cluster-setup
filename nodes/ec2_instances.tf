resource "aws_instance" "master_node" {
  ami                         = var.ami_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.kube_sg.id]
  instance_type               = var.instance_type
  associate_public_ip_address = true

  tags = {
    "Name" = "master-node"
  }

  provisioner "file" {
    source      = "../scripts/master_node_setup.sh"
    destination = "/home/ubuntu/master_node_setup.sh"
  }

  provisioner "file" {
    source      = "../scripts/kube-flannel.yaml"
    destination = "/home/ubuntu/kube-flannel.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname k8s-master.node.internal",
      "chmod +x /home/ubuntu/master_node_setup.sh",
      "./master_node_setup.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/mumbai-key.pem")
    host        = self.public_ip
  }


}

resource "aws_instance" "worker_node" {
  count                       = 2
  ami                         = var.ami_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.kube_sg.id]
  instance_type               = var.instance_type
  associate_public_ip_address = true
  depends_on                  = [aws_instance.master_node]

  tags = {
    "Name" = "worker-node-${count.index + 1}"
  }

  provisioner "file" {
    source      = "../scripts/worker_node_setup.sh"
    destination = "/home/ubuntu/worker_node_setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname k8s-worker${count.index + 1}.node.internal",
      "chmod +x /home/ubuntu/worker_node_setup.sh",
      "./worker_node_setup.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/mumbai-key.pem")
    host        = self.public_ip
  }

}