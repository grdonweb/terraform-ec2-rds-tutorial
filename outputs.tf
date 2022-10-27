output "web_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_eip.tutorial_web_eip[0].public_ip
}

output "web_public_dns" {
  description = "The public DNS address of the web server"
  value       = aws_eip.tutorial_web_eip[0].public_dns
  depends_on = [
    aws_eip.tutorial_web_eip
  ]
}

output "database_endpoint" {
  description = "The endpoint of the db"
  value       = aws_db_instance.tutorial_db.address
}

output "database_port" {
  description = "The port of db"
  value       = aws_db_instance.tutorial_db.port
}
