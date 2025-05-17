output "website" {
    description   = "http link to deployment"
    value         = "http://${aws_lb.lb.dns_name} (Give it 2 minutes..)"
}
