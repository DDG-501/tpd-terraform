variable "postgres_username" {
  description = "PostgreSQL database username"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL database password"
  type        = string
  default     = "postgres"
}

variable "tpd_web_instances_count" {
  description = "The numbe of web ui instances"
  type        = number
  default     = 1
}

variable "tpd_user_instances_count" {
  description = "The numbe of user backend instances"
  type        = number
  default     = 1
}

variable "tpd_book_instances_count" {
  description = "The numbe of book backend instances"
  type        = number
  default     = 1
}
