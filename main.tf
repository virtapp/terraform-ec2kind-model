terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "tf-sec-gr" {
  name        = "tf-provisioner-sg"
  description = "Security group for terraform provisioner"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "tf-provisioner-sg"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ubuntu"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "instance" {
  ami             = var.ec2_ami
  instance_type   = var.ec2_type
  key_name        = var.key_name
  security_groups = ["tf-provisioner-sg"]

 # Add this block to customize root volume
  root_block_device {
    volume_size = 100  # Size in GB
    volume_type = "gp3"
  }
  tags = {
    Name = "terraform-instance-provisioner"
  }

  provisioner "local-exec" {
    command = "echo http://${self.public_ip} > public_ip.txt"
  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y && apt install zip jq docker.io -y",
      "sudo wget https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.8_linux_amd64.zip",
      "sudo unzip terraform_0.14.8_linux_amd64.zip && sudo mv terraform /usr/local/bin/",
      "sudo sleep 5 && terraform version",
      "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl",
      "sudo curl -# -LO https://get.helm.sh/helm-v3.5.3-linux-amd64.tar.gz && sudo tar -xzvf helm-v3.5.3-linux-amd64.tar.gz",
      "sudo mv linux-amd64/helm /usr/local/bin/helm",
      "sudo helm version"
    ]
  }
  provisioner "remote-exec" {
  inline = [
    "cat <<EOF | sudo tee -a /tmp/local-config.tf",
    "provider "kind" {
}

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
}

resource "kind_cluster" "default" {
  name            = var.kind_cluster_name
  kubeconfig_path = pathexpand(var.kind_cluster_config_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      image = "kindest/node:v1.23.4"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

  }
}
",
    "EOF"
  ]
}
  provisioner "remote-exec" {
  inline = [
    "terraform init || exit 1",
    "terraform validate || exit ",
    "terraform plan && terraform apply -auto-approve"
  ]
}

  provisioner "file" {
    content     = self.public_ip
    destination = "/home/ubuntu/my_public_ip.txt"
  }
}
