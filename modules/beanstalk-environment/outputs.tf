output "cname" {
  value = aws_elastic_beanstalk_environment.this.cname
}

output "endpoint" {
  value = aws_elastic_beanstalk_environment.this.endpoint_url
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.this.name
}