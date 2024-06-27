variable "my_region" {
  type        = string
  default     = "us-west-1"
  description = "enter the region of your choice"
}


variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "enter the vpc cidr range of your choice"
}

variable "subnet_names" {
  type        = list(string)
  default     = ["pub1", "pub2", "pvt1", "pvt2"]
  description = "enter the desired names of subnets you want"
}

variable "data_subnets" {
  type        = list(string)
  default     = ["pub1", "pub2"]
  description = "these are only pub subnets"
}

variable "data_pvt_subnets" {
  type        = list(string)
  default     = ["pvt1", "pvt2"]
  description = "these are only pvt subnets"
}
