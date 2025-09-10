resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags, {
    Name = "${var.prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  for_each = local.subnet_cidr_blocks.public

  vpc_id                                      = aws_vpc.this.id
  availability_zone                           = each.key
  cidr_block                                  = each.value
  map_public_ip_on_launch                     = true
  enable_dns64                                = false
  enable_resource_name_dns_a_record_on_launch = true
  tags = merge(local.tags, {
    Name = "${var.prefix}-public-subnet-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = local.subnet_cidr_blocks.private

  vpc_id                                      = aws_vpc.this.id
  availability_zone                           = each.key
  cidr_block                                  = each.value
  map_public_ip_on_launch                     = false
  enable_dns64                                = false
  enable_resource_name_dns_a_record_on_launch = true
  tags = merge(local.tags, {
    Name = "${var.prefix}-private-subnet-${each.key}"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.tags, {
    Name = "${var.prefix}-internet-gateway"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(local.tags, {
    Name = "${var.prefix}-public-route-table"
  })
}
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "this" {
  count = var.need_nat_gateway ? 1 : 0

  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${var.prefix}-eip-for-nat-gateway"
  })
}
resource "aws_nat_gateway" "this" {
  count = var.need_nat_gateway ? 1 : 0

  allocation_id = aws_eip.this[0].id
  # TODO: Since the order of Availability Zones is not guaranteed, 
  # the chosen subnet from the list may vary across runs or regions.
  subnet_id = values(aws_subnet.public)[0].id
  tags = merge(local.tags, {
    Name = "${var.prefix}-nat-gateway"
  })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  dynamic "route" {
    for_each = var.need_nat_gateway ? [aws_nat_gateway.this[0].id] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = route.value
    }
  }
  tags = merge(local.tags, {
    Name = "${var.prefix}-private-route-table"
  })
  depends_on = [aws_nat_gateway.this]
}
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
