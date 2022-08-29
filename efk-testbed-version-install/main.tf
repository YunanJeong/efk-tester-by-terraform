/*
Terraform AWS example
awscli가 설치되어 있고, Access Key, Secret Key가 등록되어 있어야 한다.
*/
######################################################################
# Provisioning
######################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 0.14.9"
}

# setup to specified provider
provider "aws" {
  profile = "default"
  region  = "ap-northeast-2" # seoul region
}

######################################################################
# Set Up Security Groups
######################################################################
# 보안그룹 생성 or 수정
resource "aws_security_group" "basic_sgroup"{
  name = "basic_sgroup"
  # Inbound Rule 1
  ingress {
    # from, to로 포트 허용 범위를 나타낸다.
    from_port = 22
    to_port = 22
    description = "for ssh connection"
    protocol = "tcp"
    cidr_blocks = var.my_ip_list
  }

  # Outbound Rule 1 (아래 예시는 설정하지 않은것과 같은, 전체 허용 표기법이다.)
  egress{
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sgroup_for_fluentd"{
  name = "sgroup_for_fluentd"
  ingress {
    from_port = 5044
    to_port = 5045
    description = "Allows beats data"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sgroup_for_elasticsearch"{
  name = "sgroup_for_elasticsearch"
  ingress {
    from_port = 9200
    to_port = 9299
    description = "Allows data from client like fluentd, logstash,..."
    protocol = "tcp"
    cidr_blocks = concat(var.my_ip_list, ["${aws_instance.fluentd.public_ip}/32"])
  }
  ingress {
    from_port = 9300
    to_port = 9399
    description = "Allows ElasticSearch cluster discovery"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0", ]
  }
}

resource "aws_security_group" "sgroup_for_kibana"{
  name = "sgroup_for_kibana"
  ingress {
    from_port = 5601
    to_port = 5601
    description = "Allows to access Kibana web"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

######################################################################
# Set Up Instance for fluentd
######################################################################
resource "aws_instance" "fluentd" {
  ami           = var.ami_fluentd
  instance_type = var.instance_type_fluentd
  tags = merge(var.tags, {Name = var.tag_name_fluentd}, )
  key_name = var.key_pair_name
  security_groups = [aws_security_group.basic_sgroup.name, aws_security_group.sgroup_for_fluentd.name, ]
}

######################################################################
# Set Up Instance for ElasticSearch
######################################################################
resource "aws_instance" "elasticsearch" {
  ami           = var.ami_elasticsearch
  instance_type = var.instance_type_elasticsearch
  tags = merge(var.tags, {Name = var.tag_name_elasticsearch}, )
  key_name = var.key_pair_name
  security_groups = [
    aws_security_group.basic_sgroup.name,
    aws_security_group.sgroup_for_elasticsearch.name,
    aws_security_group.sgroup_for_kibana.name,
  ]
}

#################################################
# EFK 설정파일 셋업
#################################################
data "template_file" "fluentd" {
  template = file("${path.module}/efk_config/td-agent.escape.conf")
  vars = {
    elasticsearch-public-ip-here = aws_instance.elasticsearch.public_ip
  }
}

data "template_file" "elasticsearch" {
  template = file("${path.module}/efk_config/elasticsearch.yml")
  vars = {
    hostname-here = split(".", aws_instance.elasticsearch.private_dns)[0]  # hostname
  }
}

data "template_file" "kibana" {
  template = file("${path.module}/efk_config/kibana.yml")
  vars = {
    public-ip-here = aws_instance.elasticsearch.public_ip
  }
}

#################################################
# Fluentd Commands
#################################################
resource "null_resource" "fluentd_remote"{

  # remote-exec를 위한 ssh connection 셋업
  connection {
    type = "ssh"
    host = aws_instance.fluentd.public_ip
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = false
  }

  # 원격 인스턴스로 설정 파일 전송
  provisioner "file" {
    content = data.template_file.fluentd.rendered
    destination = "/home/ubuntu/td-agent.conf"
  }

  # 실행된 원격 인스턴스에서 수행할 cli명령어
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait", # cloud-init이 끝날 떄 까지 기다린다. 에러 예방 차원에서 항상 써준다.

      # td-agent 셋업
      "wget ${var.version_fluentd}",
      "sudo apt install -y ./*.deb",
      "sudo mv /home/ubuntu/td-agent.conf /etc/td-agent/td-agent.conf",

      # td-agent filebeat 플러그인 설치
      "wget https://rubygems.org/downloads/fluent-plugin-beats-1.1.0.gem",
      "sudo td-agent-gem install ./*.gem",

      # 실행(td-agent는 마지막에 restart 해주는게 안정적이다.)
      "sudo systemctl daemon-reload",
      "sudo systemctl enable td-agent.service && sudo systemctl restart td-agent.service",

      # td-agent dependency deb설치파일 다운로드
        # 인터넷 환경에선 td-agent 설치시 dependency가 자동설치되므로 필요없다.
        # 비인터넷 환경 설치시, 인터넷 환경에서 이와같이 dependency를 별도 다운로드해서 파일을 옮기면 된다.
        # ubuntu/debian repository에 td-agent가 등록되어있지 않으므로, td-agent 설치 후 실행해야 한다.
      "mkdir depend && cd depend",
      "apt-cache depends -i td-agent=${var.version_num_fluentd} | awk '/Depends:/ {print $2}' | xargs apt-get download",
      "cd",
    ]
  }
}

#################################################
# ElasticSearch Commands
#################################################
resource "null_resource" "elasticsearch_remote"{

  # remote-exec를 위한 ssh connection 셋업
  connection {
    type = "ssh"
    host = aws_instance.elasticsearch.public_ip
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = false
  }

  # 원격 인스턴스로 설정 파일 전송
  provisioner "file" {
    content = data.template_file.elasticsearch.rendered
    destination = "/home/ubuntu/elasticsearch.yml"
  }
  provisioner "file" {
    content = data.template_file.kibana.rendered
    destination = "/home/ubuntu/kibana.yml"
  }

  # 실행된 원격 인스턴스에서 수행할 cli명령어
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait", # cloud-init이 끝날 떄 까지 기다린다. 에러 예방 차원에서 항상 써준다.

      "wget ${var.version_elasticsearch}",
      "wget ${var.version_kibana}",
      "sudo apt install -y ./*.deb",
      "sudo mv /home/ubuntu/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml",
      "sudo mv /home/ubuntu/kibana.yml /etc/kibana/kibana.yml",

      # 가용램의 절반으로 elasticsearch 힙메모리 설정
      "sudo cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.d/",
      "RAM=$(echo $(free --giga|grep Mem) | cut -f2 -d' ')   &&   HALF_RAM=`echo $((RAM/2))`",
      "sudo sh -c \"echo '-Xms'$HALF_RAM'g''\n''-Xmx'$HALF_RAM'g' >> /etc/elasticsearch/jvm.options.d/jvm.options\" ",

      "sudo systemctl daemon-reload",
      "sudo systemctl enable elasticsearch.service kibana.service",
      "sudo systemctl start elasticsearch.service kibana.service",
    ]
  }
}

