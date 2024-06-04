variable "postgres_username" {
  description = "PostgreSQL database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "postgres"
  sensitive   = true
}
