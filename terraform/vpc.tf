resource  "aws_vpc" "vpc" {
    cidr_block          = var.vpc-cidr
    tags = {
        Name            = var.vpc-name
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id              = aws_vpc.vpc.id
    count               = local.az-width
    cidr_block          = cidrsubnet(var.vpc-cidr,var.subnet-shrink,count.index * 2 +2)
    availability_zone   = element(data.aws_availability_zones.all.names, count.index)
    tags = {
        Name            = "${var.vpc-name}-pub-az-${substr(element(data.aws_availability_zones.all.names, count.index), -1, 1)}"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id              = aws_vpc.vpc.id
    count               = local.az-width
    cidr_block          = cidrsubnet(var.vpc-cidr,var.subnet-shrink,count.index * 2 + local.subnet-offset + 2)
    availability_zone   = element(data.aws_availability_zones.all.names, count.index)
    tags = {
        Name            = "${var.vpc-name}-priv-az-${substr(element(data.aws_availability_zones.all.names, count.index), -1, 1)}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id              = aws_vpc.vpc.id
    tags = {
        Name            = "${var.vpc-name}-igw"
    }
}

resource "aws_eip" "nat-ips" {
    count               = local.az-width
    depends_on          = [ aws_internet_gateway.igw ]
    tags = {
        Name            = "${var.vpc-name}-eip-az-${substr(element(data.aws_availability_zones.all.names, count.index), -1, 1)}"
    }
}

resource "aws_nat_gateway" "ngw" {
    count               = local.az-width
    allocation_id       = aws_eip.nat-ips.*.id[count.index]
    subnet_id           = aws_subnet.public_subnet.*.id[count.index]
    tags = {
        Name            = "${var.vpc-name}-nat-az-${substr(element(data.aws_availability_zones.all.names, count.index), -1, 1)}"
    }
}

resource "aws_route_table" "public" {
    vpc_id              = aws_vpc.vpc.id
    route {
        cidr_block      = "0.0.0.0/0"
        gateway_id      = aws_internet_gateway.igw.id
    }
    tags = {
        Name            = "${var.vpc-name}-pub-rt"
    }
}

resource "aws_route_table" "private" {
    count               = local.az-width
    vpc_id              = aws_vpc.vpc.id
    route {
        cidr_block      = "0.0.0.0/0"
        nat_gateway_id  = element(aws_nat_gateway.ngw.*.id, count.index)
    }
    tags = {
        Name            = "${var.vpc-name}-priv-rt-az-${substr(element(data.aws_availability_zones.all.names, count.index), -1, 1)}"
    }
}

resource "aws_route_table_association" "public_link" {
    count               = local.az-width
    subnet_id           = element(aws_subnet.public_subnet.*.id,count.index)
    route_table_id      = aws_route_table.public.id
}

resource "aws_route_table_association" "private_link" {
    count               = local.az-width
    subnet_id           = element(aws_subnet.private_subnet.*.id,count.index)
    route_table_id      = element(aws_route_table.private.*.id, count.index)
}
