data "aws_availability_zones" "all" {}

locals {
    az-width            = var.az-width == null ? length(data.aws_availability_zones.all.names) : var.az-width
    subnet-offset       = pow(2,(tolist(regex("/(.*)", var.vpc-cidr))[0] + var.subnet-shrink - 32) * -1) / 2
}

variable "vpc-cidr" {
    default             = "10.0.0.0/16"
}

variable "subnet-shrink" {
    default             = 8
    description         = "Additional subnet bits during subnet calculation from vpc cidr scope"
}

variable "vpc-name" {
    default             = "nginx-demo"  
}

variable "az-width" {
    default             = null
    type                = number
    validation {
        condition       = (var.az-width == null ||
                        (
                            coalesce(var.az-width, 0) >= 1 &&
                            coalesce(var.az-width, length(data.aws_availability_zones.all.names) + 1) <=
                            length(data.aws_availability_zones.all.names)
                        )
                  )
        error_message   = "!!! AZ width is out of range"
    }
}
