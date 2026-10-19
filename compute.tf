# Parámetro específico de kernel: no seguir kernel-default cuando cambie de versión.
data "aws_ssm_parameter" "globomatics_al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.18-x86_64"
}

data "aws_availability_zones" "globomatics_available" {
  state = "available"
}

resource "aws_key_pair" "globomatics" {
  key_name   = "key-${local.suffix}"
  public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  tags       = { Name = "key-${local.suffix}" }
}

resource "aws_instance" "globomatics_client" {
  ami                         = data.aws_ssm_parameter.globomatics_al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.globomatics_public.id
  private_ip                  = "10.42.1.10"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.globomatics.key_name
  vpc_security_group_ids      = [aws_security_group.globomatics_client.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
    tags                  = { Name = "ebs-cliente-root-${local.suffix}", Project = local.project, ManagedBy = "OpenTofu" }
  }
  tags       = { Name = "ec2-cliente-${local.suffix}", Role = "client" }
  depends_on = [aws_route_table_association.globomatics_public]
}

resource "aws_instance" "globomatics_backend" {
  ami                         = data.aws_ssm_parameter.globomatics_al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.globomatics_public.id
  private_ip                  = "10.42.1.20"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.globomatics.key_name
  vpc_security_group_ids      = [aws_security_group.globomatics_backend.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
    tags                  = { Name = "ebs-backend-root-${local.suffix}", Project = local.project, ManagedBy = "OpenTofu" }
  }
  tags       = { Name = "ec2-backend-${local.suffix}", Role = "backend" }
  depends_on = [aws_route_table_association.globomatics_public]
}
