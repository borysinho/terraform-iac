output "servers" {
  description = "Direcciones de ambos EC2. Las IP públicas pueden cambiar al detener/iniciar."
  value = {
    client = {
      id         = aws_instance.globomatics_client.id
      public_ip  = aws_instance.globomatics_client.public_ip
      public_dns = aws_instance.globomatics_client.public_dns
      private_ip = aws_instance.globomatics_client.private_ip
    }
    backend = {
      id         = aws_instance.globomatics_backend.id
      public_ip  = aws_instance.globomatics_backend.public_ip
      private_ip = aws_instance.globomatics_backend.private_ip
    }
  }
}

output "ssh_commands" {
  value = {
    client  = "ssh -i ~/globomatics-ec2 ec2-user@${aws_instance.globomatics_client.public_ip}"
    backend = "ssh -i ~/globomatics-ec2 ec2-user@${aws_instance.globomatics_backend.public_ip}"
  }
}
