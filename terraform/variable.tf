variable "region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "shuvabuc007"
}

variable "source_folder" {
  type    = string
  default = "src/"
}

variable "target_folder" {
  type    = string
  default = "target/"

}

variable "inbound_folder" {
  type    = string
  default = "inbound/"

}
