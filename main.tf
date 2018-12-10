provider "aws"{
    region = "${var.aws_region}"
    profile = "${var.aws_profile}"
}

resource "aws_iam_instance_profile" "s3_access_profile" {
    name = "s3_access"
    role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
    name = "s3_access_policy"
    role = "${aws_iam_role.s3_access_role.id}"

    policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": "s3:*",
"Resource": "*"
}
]
}
    EOF
}

resource "aws_iam_role" "s3_access_role" {
    name = "s3_access_role"

    assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "ec2.amazonaws.com"
},
"Effect": "Allow",
"Sid": ""
}
]
}
    EOF
}

resource "aws_vpc" "dimas_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags {
        Name = "vpc_dimas"
    }
}

resource "aws_internet_gateway" "dimas_igw" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"

    tags {
        Name = "igw_dimas"
    }
}

resource "aws_route_table" "dimas_rtb_pub" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"
    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.dimas_igw.id}"
    }
    tags = {
        Name = "rtb_pub_dimas"
    }
}

resource "aws_default_route_table" "dimas_rtb_pri" {
    default_route_table_id = "${aws_vpc.dimas_vpc.default_route_table_id}"

    tags = {
        Name = "rtb_pri_dimas"
    }
}

resource "aws_subnet" "public1_subnet" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"
    cidr_block = "${var.cidrs["public1"]}"
    map_public_ip_on_launch = true
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    
    tags = {
        Name = "sub_public1"
    }
}

resource "aws_subnet" "public2_subnet" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"
    cidr_block = "${var.cidrs["public2"]}"
    map_public_ip_on_launch = true
    availability_zone = "${data.aws_availability_zones.available.names[1]}"

    tags = {
        Name = "sub_public2"
    }
}

resource "aws_subnet" "private1_subnet" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"
    cidr_block = "${var.cidrs["private1"]}"
    map_public_ip_on_launch = false
    availability_zone = "${data.aws_availability_zones.available.names[0]}"

    tags = {
        Name = "sub_private1"
    }
}

resource "aws_subnet" "private2_subnet" {
    vpc_id = "${aws_vpc.dimas_vpc.id}"
    cidr_block = "${var.cidrs["private2"]}"
    map_public_ip_on_launch = false
    availability_zone = "${data.aws_availability_zones.available.names[1]}"

    tags = {
        Name = "sub_private2"
    }
}

resource "aws_route_table_association" "public1_assoc" {
    subnet_id = "${aws_subnet.public1_subnet.id}"
    route_table_id = "${aws_route_table.dimas_rtb_pub.id}"
}

resource "aws_route_table_association" "public2_assoc" {
    subnet_id = "${aws_subnet.public2_subnet.id}"
    route_table_id = "${aws_route_table.dimas_rtb_pub.id}"
}

resource "aws_route_table_association" "private1_assoc" {
    subnet_id = "${aws_subnet.private1_subnet.id}"
    route_table_id = "${aws_default_route_table.dimas_rtb_pri.id}"
}

resource "aws_route_table_association" "private2_assoc" {
    subnet_id = "${aws_subnet.private2_subnet.id}"
    route_table_id = "${aws_default_route_table.dimas_rtb_pri.id}"
}

resource "aws_security_group" "dimas_sg" {
    name = "dimas_secgroup"
    vpc_id = "${aws_vpc.dimas_vpc.id}"

    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.localip}"]
    }

    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.localip}"]
    }

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}