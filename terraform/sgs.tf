resource "aws_security_group" "ecs" {
    name                            = "${var.vpc-name}-ecs-sg"
    description                     = "Security group for ECS node traffic"
    vpc_id                          = aws_vpc.vpc.id
    tags = {
        Name                        = "${var.vpc-name}-ecs-sg"
    }
    lifecycle {
        create_before_destroy       = true
    }
}

resource "aws_vpc_security_group_ingress_rule" "http_from_lb" {
    security_group_id               = aws_security_group.ecs.id
    from_port                       = 80
    to_port                         = 80
    ip_protocol                     = "tcp"
    referenced_security_group_id    = aws_security_group.lb.id
}

resource "aws_vpc_security_group_egress_rule" "httpd_to_any" {
    security_group_id               = aws_security_group.ecs.id
    from_port                       = 443
    to_port                         = 443
    ip_protocol                     = "tcp"
    cidr_ipv4                       = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp_to_any" {
    security_group_id               = aws_security_group.ecs.id
    from_port                       = 53
    to_port                         = 53
    ip_protocol                     = "tcp"
    cidr_ipv4                       = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns_udp_to_any" {
    security_group_id               = aws_security_group.ecs.id
    from_port                       = 53
    to_port                         = 53
    ip_protocol                     = "udp"
    cidr_ipv4                       = "0.0.0.0/0"
}




resource "aws_security_group" "lb" {
    name                            = "${var.vpc-name}-lb-sg"
    description                     = "Security group for load balancer traffic"
    vpc_id                          = aws_vpc.vpc.id
    tags = {
        Name                        = "${var.vpc-name}-lb-sg"
    }
    lifecycle {
        create_before_destroy       = true
    }
}

resource "aws_vpc_security_group_egress_rule" "http_to_ecs" {
    security_group_id               = aws_security_group.lb.id
    from_port                       = 80
    to_port                         = 80
    ip_protocol                     = "tcp"
    referenced_security_group_id    = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "httpd_from_any" {
    security_group_id               = aws_security_group.lb.id
    from_port                       = 80
    to_port                         = 80
    ip_protocol                     = "tcp"
    cidr_ipv4                       = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "httpsd_from_any" {
    security_group_id               = aws_security_group.lb.id
    from_port                       = 443
    to_port                         = 443
    ip_protocol                     = "tcp"
    cidr_ipv4                       = "0.0.0.0/0"
}