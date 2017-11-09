#!/bin/bash
# @author: Roman

. ./confrc

aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name $as_group_name \
    --force-delete

aws autoscaling delete-launch-configuration \
    --launch-configuration-name $launch_conf_name

aws elb delete-load-balancer \
    --load-balancer-name $elb_name
