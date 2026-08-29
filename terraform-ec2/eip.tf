# eip.tf - Static public IP and the CloudFront origin DNS record
#
# The instance's default public IP changes on every stop/start, so DNS
# must never point at it. An Elastic IP is stable for the lifetime of
# this root -- and free while attached to a running instance (the
# regular in-use IPv4 charge applies either way).

resource "aws_eip" "blog" {
  domain = "vpc"

  tags = {
    Name = "blog-ec2-eip"
  }
}

resource "aws_eip_association" "blog" {
  instance_id   = aws_instance.blog.id
  allocation_id = aws_eip.blog.id
}

# Origin record for CloudFront. CloudFront needs a DNS name as origin,
# not an IP -- this name is what the distribution points at after the
# migration away from Lightsail. TTL 60 keeps a rollback fast.
data "aws_route53_zone" "main" {
  name = "aws.his4irness23.de"
}

resource "aws_route53_record" "origin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "origin-ec2.aws.his4irness23.de"
  type    = "A"
  ttl     = 60
  records = [aws_eip.blog.public_ip]
}
