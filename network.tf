resource "aws_vpc" "globomatics" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-${local.suffix}" }
}

resource "aws_subnet" "globomatics_public" {
  vpc_id                  = aws_vpc.globomatics.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = data.aws_availability_zones.globomatics_available.names[0]
  map_public_ip_on_launch = false # La IP pública se solicita explícitamente en cada EC2.
  tags                    = { Name = "subnet-publica-${local.suffix}" }
}

resource "aws_internet_gateway" "globomatics" {
  vpc_id = aws_vpc.globomatics.id
  tags   = { Name = "igw-${local.suffix}" }
}

resource "aws_route_table" "globomatics_public" {
  vpc_id = aws_vpc.globomatics.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.globomatics.id
  }
  tags = { Name = "rtb-publica-${local.suffix}" }
}

# AWS no admite nombres/etiquetas en las asociaciones de tablas de rutas.
resource "aws_route_table_association" "globomatics_public" {
  subnet_id      = aws_subnet.globomatics_public.id
  route_table_id = aws_route_table.globomatics_public.id
}

resource "aws_security_group" "globomatics_client" {
  name        = "secgrp-cliente-${local.suffix}"
  description = "Cliente HTTP/HTTPS publico; SSH solo desde la IP administrativa"
  vpc_id      = aws_vpc.globomatics.id
  tags        = { Name = "secgrp-cliente-${local.suffix}" }
}

resource "aws_security_group" "globomatics_backend" {
  name        = "secgrp-backend-${local.suffix}"
  description = "API solo desde cliente; SSH solo desde la IP administrativa; sin acceso a BD"
  vpc_id      = aws_vpc.globomatics.id
  tags        = { Name = "secgrp-backend-${local.suffix}" }
}

resource "aws_vpc_security_group_ingress_rule" "globomatics_ssh" {
  for_each = {
    client  = aws_security_group.globomatics_client.id
    backend = aws_security_group.globomatics_backend.id
  }
  security_group_id = each.value
  description       = "SSH desde la IP administrativa"
  cidr_ipv4         = var.ssh_source_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  tags              = { Name = "sgr-ingress-${each.key}-ssh-${local.suffix}" }
}

resource "aws_vpc_security_group_ingress_rule" "globomatics_web" {
  for_each          = { http = 80, https = 443 }
  security_group_id = aws_security_group.globomatics_client.id
  description       = "Acceso web publico ${each.key}"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  tags              = { Name = "sgr-ingress-cliente-${each.key}-${local.suffix}" }
}

resource "aws_vpc_security_group_ingress_rule" "globomatics_api" {
  security_group_id            = aws_security_group.globomatics_backend.id
  description                  = "TCP 8090 por IP privada desde el servidor cliente"
  referenced_security_group_id = aws_security_group.globomatics_client.id
  ip_protocol                  = "tcp"
  from_port                    = 8090
  to_port                      = 8090
  tags                         = { Name = "sgr-ingress-backend-api-${local.suffix}" }
}

# Permite instalar paquetes y realizar las configuraciones manuales solicitadas.
resource "aws_vpc_security_group_egress_rule" "globomatics_outbound" {
  for_each = {
    client  = aws_security_group.globomatics_client.id
    backend = aws_security_group.globomatics_backend.id
  }
  security_group_id = each.value
  description       = "Salida para actualizaciones y configuracion"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags              = { Name = "sgr-egress-${each.key}-${local.suffix}" }
}
