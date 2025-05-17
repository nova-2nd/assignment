resource "aws_lb" "lb" {
    name                    = "${var.vpc-name}-lb"
    internal                = false
    load_balancer_type      = "application"
    security_groups         = [aws_security_group.lb.id]
    subnets                 = [for subnet in aws_subnet.public_subnet : subnet.id]
}

resource "aws_lb_target_group" "lb-target" {
    vpc_id                  = aws_vpc.vpc.id
    name                    = "${var.vpc-name}-lb-tg"
    port                    = 80
    protocol                = "HTTP"
    target_type             = "ip"
}

resource "aws_lb_listener" "lb-ls-https" {
    load_balancer_arn       = aws_lb.lb.arn
    port                    = 443
    protocol                = "HTTPS"
    ssl_policy              = "ELBSecurityPolicy-2016-08"
    certificate_arn         = aws_acm_certificate.acm-cert.arn
    default_action {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.lb-target.arn
    }
}

resource "aws_lb_listener" "lb-ls-http" {
    load_balancer_arn       = aws_lb.lb.arn
    port                    = 80
    protocol                = "HTTP"
    default_action {
        type                = "redirect"
        redirect {
            port            = 443
            protocol        = "HTTPS"
            status_code     = "HTTP_301"
        }
    }
}

resource "tls_private_key" "rsa-key" {
    algorithm               = "RSA"
}

resource "tls_self_signed_cert" "lb-cert" {
    private_key_pem         = tls_private_key.rsa-key.private_key_pem
    validity_period_hours   = 8760
    subject {
        common_name         = aws_lb.lb.dns_name
        organization        = var.vpc-name
    }
    dns_names               = [aws_lb.lb.dns_name]
    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth"
    ]
}

resource "aws_acm_certificate" "acm-cert" {
    private_key             = tls_private_key.rsa-key.private_key_pem
    certificate_body        = tls_self_signed_cert.lb-cert.cert_pem
}