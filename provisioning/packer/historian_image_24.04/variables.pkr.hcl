# Input Variables

variable "ansible_groups" {
  type        = list(string)
  description = "The ansible groups to assign to the build host"
  default     = ["all"]
}

variable "base_image" {
  type        = string
  description = "The base image to build from"
}

variable "image_name" {
  type        = string
  description = "The name to use for the resulting image"
}

variable "timestamp_image" {
  type        = bool
  description = "Image name is suffixed with a build timestamp if set to true"
  default     = true
}

variable "build_user" {
  type        = string
  description = "User to use when building the image"
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for the build host"
}

variable "region" {
  type        = string
  description = "The region to use for the build host"
}
