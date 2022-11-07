variable "resource_group_name_prefix" {
  default     = "minecraft"
  description = "Resource group prefix"
}

variable "kubernetes_version" {
  default = "1.18"
}

variable "workers_count" {
  default = "3"
}

variable "cluster_name" {
  type = string
}

variable "location" {
  type = string
}