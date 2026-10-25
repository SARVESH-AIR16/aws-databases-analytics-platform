resource "aws_vpc" "application" {
  cidr_block           = var.vpc1_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "db-analytics-application-vpc"
  }
}

resource "aws_vpc" "analytics" {
  cidr_block           = var.vpc2_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "db-analytics-analytics-vpc"
  }
}

resource "aws_subnet" "application_public" {
  vpc_id                  = aws_vpc.application.id
  cidr_block              = var.vpc1_public_subnet_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = false

  tags = {
    Name = "application-public-subnet"
  }
}

resource "aws_subnet" "application_private" {
  vpc_id            = aws_vpc.application.id
  cidr_block        = var.vpc1_private_subnet_cidr
  availability_zone = var.availability_zone_a

  tags = {
    Name = "application-private-subnet-a"
  }
}

resource "aws_subnet" "application_private_b" {
  vpc_id            = aws_vpc.application.id
  cidr_block        = var.vpc1_private_subnet_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "application-private-subnet-b"
  }
}

resource "aws_subnet" "analytics_private" {
  vpc_id            = aws_vpc.analytics.id
  cidr_block        = var.vpc2_private_subnet_cidr
  availability_zone = var.availability_zone_a

  tags = {
    Name = "analytics-private-subnet-a"
  }
}

resource "aws_subnet" "analytics_private_b" {
  vpc_id            = aws_vpc.analytics.id
  cidr_block        = var.vpc2_private_subnet_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "analytics-private-subnet-b"
  }
}

resource "aws_internet_gateway" "application" {
  vpc_id = aws_vpc.application.id

  tags = {
    Name = "application-internet-gateway"
  }
}

resource "aws_route_table" "application_public" {
  vpc_id = aws_vpc.application.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.application.id
  }

  tags = {
    Name = "application-public-routes"
  }
}

resource "aws_route_table" "application_private" {
  vpc_id = aws_vpc.application.id

  tags = {
    Name = "application-private-routes"
  }
}

resource "aws_route_table" "analytics_private" {
  vpc_id = aws_vpc.analytics.id

  tags = {
    Name = "analytics-private-routes"
  }
}

resource "aws_route_table_association" "application_public" {
  subnet_id      = aws_subnet.application_public.id
  route_table_id = aws_route_table.application_public.id
}

resource "aws_route_table_association" "application_private" {
  subnet_id      = aws_subnet.application_private.id
  route_table_id = aws_route_table.application_private.id
}

resource "aws_route_table_association" "application_private_b" {
  subnet_id      = aws_subnet.application_private_b.id
  route_table_id = aws_route_table.application_private.id
}

resource "aws_route_table_association" "analytics_private" {
  subnet_id      = aws_subnet.analytics_private.id
  route_table_id = aws_route_table.analytics_private.id
}

resource "aws_route_table_association" "analytics_private_b" {
  subnet_id      = aws_subnet.analytics_private_b.id
  route_table_id = aws_route_table.analytics_private.id
}

resource "aws_vpc_peering_connection" "application_analytics" {
  vpc_id      = aws_vpc.application.id
  peer_vpc_id = aws_vpc.analytics.id
  auto_accept = true

  tags = {
    Name = "application-analytics-peering"
  }
}

resource "aws_route" "application_to_analytics" {
  route_table_id            = aws_route_table.application_private.id
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.application_analytics.id
}

resource "aws_route" "analytics_to_application" {
  route_table_id            = aws_route_table.analytics_private.id
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.application_analytics.id
}
