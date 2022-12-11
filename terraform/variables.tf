variable "tag" {
  type        = string
  default     = "latest"
  description = "the tag of the go servers to deploy"
}

variable "log_group_name" {
  type        = string
  default     = "services_log_group"
  description = "log group name"
}

variable "victim_url" {
  type        = string
  default     = "victim"
  description = "url prefix to reach out to victim"
}

variable "table_name" {
  type        = string
  default     = "ip_table"
  description = "dynamo db table name"
}

variable "email" {
  type        = string
  description = "where to send emails to"
}


