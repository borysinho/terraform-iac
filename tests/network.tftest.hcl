# Pruebas locales sin credenciales AWS y sin crear recursos.
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-east-2a"] }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
}

run "network_and_access" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_vpc_security_group_ingress_rule.globomatics_ssh :
      rule.cidr_ipv4 == "181.114.108.136/32" && rule.from_port == 22 && rule.to_port == 22
    ])
    error_message = "Ambos servidores deben permitir SSH solo desde la IP administrativa."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.globomatics_api.from_port == 8090 &&
      aws_vpc_security_group_ingress_rule.globomatics_api.to_port == 8090 &&
      aws_vpc_security_group_ingress_rule.globomatics_api.referenced_security_group_id == aws_security_group.globomatics_client.id &&
      aws_vpc_security_group_ingress_rule.globomatics_api.cidr_ipv4 == null
    )
    error_message = "La API solo debe aceptar 8090 desde el grupo del cliente."
  }

  assert {
    condition = alltrue([
      for rule in aws_vpc_security_group_ingress_rule.globomatics_web :
      contains([80, 443], rule.from_port) && rule.from_port == rule.to_port && rule.cidr_ipv4 == "0.0.0.0/0"
    ])
    error_message = "La web debe admitir HTTP y HTTPS desde Internet."
  }

  assert {
    condition = alltrue([
      for instance in [aws_instance.globomatics_client, aws_instance.globomatics_backend] :
      instance.associate_public_ip_address && instance.instance_type == "t3.micro" && instance.key_name == aws_key_pair.globomatics.key_name
    ])
    error_message = "Ambos EC2 deben ser t3.micro, tener IP pública y compartir la clave del proyecto."
  }

}

run "reject_broad_ssh" {
  command = plan
  variables {
    ssh_source_cidr = "0.0.0.0/0"
  }
  expect_failures = [var.ssh_source_cidr]
}
