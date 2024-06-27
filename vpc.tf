resource "aws_vpc" "trailvpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "subnets" {
  count      = length(var.subnet_names)
  vpc_id     = aws_vpc.trailvpc.id
  cidr_block = cidrsubnet(aws_vpc.trailvpc.cidr_block, 8, count.index)
  tags = {
    Name = var.subnet_names[count.index]
  }
  depends_on = [aws_vpc.trailvpc]
}

resource "aws_internet_gateway" "mygateway" {
  vpc_id = local.myvpcid
  tags = {
    "Name" = "myGw"
  }
  depends_on = [aws_vpc.trailvpc]
}

resource "aws_route_table" "publicRoteTable" {
  vpc_id = local.myvpcid

}

resource "aws_route" "publicRoute" {
  route_table_id         = local.pubRTid
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mygateway.id
  depends_on             = [aws_route_table.publicRoteTable] #  explicit dependency
}


data "aws_subnets" "publicSubnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.trailvpc.id]

  }
  filter {
    name   = "tag:Name"
    values = var.data_subnets # insert values here
  }
  depends_on = [aws_subnet.subnets]

}

resource "aws_route_table_association" "PubSubAssociation" {
  count          = length(var.data_subnets)
  subnet_id      = element(data.aws_subnets.publicSubnets.ids, count.index)
  route_table_id = aws_route_table.publicRoteTable.id
  depends_on     = [aws_subnet.subnets, aws_vpc.trailvpc]
}

resource "aws_eip" "myeip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "mynatgateway" {
  allocation_id = aws_eip.myeip.allocation_id
  subnet_id     = aws_subnet.subnets[0].id
  depends_on    = [aws_eip.myeip]
}

resource "aws_route_table" "pvtRt" {
  vpc_id = aws_vpc.trailvpc.id
  route {
    nat_gateway_id = aws_nat_gateway.mynatgateway.id
    cidr_block     = "0.0.0.0/0"
  }
  depends_on = [aws_nat_gateway.mynatgateway]
}

data "aws_subnets" "pvtSubnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.trailvpc.id]

  }
  filter {
    name   = "tag:Name"
    values = var.data_pvt_subnets # insert values here
  }
  depends_on = [aws_subnet.subnets]

}


resource "aws_route_table_association" "pvtSubnetAssociation" {
  count          = length(var.data_pvt_subnets)
  subnet_id      = element(data.aws_subnets.pvtSubnets.ids, count.index)
  route_table_id = aws_route_table.pvtRt.id
}


