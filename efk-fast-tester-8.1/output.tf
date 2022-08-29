# $terraform apply 후, 아래 내용에 해당하는 정보가 stdout으로 출력된다.
# 여기서는 인스턴스 ID와 IP 예시이다.
# infra가 실행중일 떄, $terraform output으로도 조회가능하다.
# output들은 현재 infra나 다른 terraform 프로젝트에서 사용가능하다.

######################################################################
# Set Up fluentd
######################################################################
output "instance_id_fluentd" {
  description = "ID of the EC2 instance"
  value       = aws_instance.fluentd.id
}
output "instance_public_ip_fluentd" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.fluentd.public_ip
}
output "instance_tags_fluentd" {
  description = "Instance Tags"
  value = aws_instance.fluentd.tags
}

######################################################################
#Set Up ElasticSearch
######################################################################
output "instance_id_elasticsearch" {
  description = "ID of the EC2 instance"
  value       = aws_instance.elasticsearch.id
}
output "instance_public_ip_elasticsearch" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.elasticsearch.public_ip
}
output "instance_tags_elasticsearch" {
  description = "Instance Tags"
  value = aws_instance.elasticsearch.tags
}


