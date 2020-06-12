# alb.tf

resource "aws_alb" "main" {
  name            = "sample-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]

  tags = local.common_tags  
}

resource "aws_alb_target_group" "app" {
  name        = "sample-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "2"
    interval            = "5"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = local.common_tags
}

# Redirect all traffic from the ALB to the target group
# resource "aws_alb_listener" "front_end" {
#   load_balancer_arn = aws_alb.main.id
#   port              = var.client_app_port
#   protocol          = "HTTP"

#   default_action {
#     target_group_arn = aws_alb_target_group.app.id
#     type             = "forward"
#   }
# }


# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = var.client_app_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }  
}

resource "aws_alb_listener" "front_end_secure" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.startup_sample_cert.arn


  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}

resource "aws_acm_certificate" "startup_sample_cert" {
  domain_name       = var.cert_ssl_domain
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name         = local.dns_domain_extract.domain_tld
  private_zone = false
}

resource "aws_route53_record" "startup_sample" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.cert_ssl_domain
  type    = "A"  
  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.startup_sample_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.startup_sample_cert.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone.zone_id
  records = [aws_acm_certificate.startup_sample_cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.startup_sample_cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

output "dns_name" {
  value = aws_route53_record.startup_sample.fqdn
}
