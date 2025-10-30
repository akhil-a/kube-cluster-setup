variable "instance_type" {
  description = "t2 medium instance type"
  type        = string
}

variable "ami_id" {
  description = "ami id"
  type        = string
}

variable "key_name" {
  description = "key name for ec2 instance"
  type        = string
}