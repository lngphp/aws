#!/bin/bash
# @author: Roman

. ./confrc

echo create-load-balancer $elb_name
aws elb create-load-balancer \
    --load-balancer-name $elb_name \
    --listeners $elb_listeners \
    --availability-zones $availability_zones

echo modify-load-balancer-attributes
aws elb modify-load-balancer-attributes \
    --load-balancer-name $elb_name \
    --load-balancer-attributes "{\"ConnectionDraining\":{\"Enabled\":true,\"Timeout\":300}}"

echo create-launch-configuration
aws autoscaling create-launch-configuration \
    --launch-configuration-name $launch_conf_name \
    --image-id $image_id \
    --instance-type $instance_type \
    --key-name $key_name \
    --security-groups $security_group_ids \
    --iam-instance-profile $iam_instance_profile

echo create-auto-scaling-group
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name $as_group_name \
    --launch-configuration-name $launch_conf_name \
    --availability-zones $availability_zones \
    --load-balancer-names $elb_name \
    --max-size $max_size \
    --min-size $min_size \
    --desired-capacity $desired_capacity \
    --health-check-type $health_check_type \
    --health-check-grace-period $health_check_grace_period \
    --tags $tags

# AS Triggers
echo 'put-scaling-policy in'
arn=$(aws autoscaling put-scaling-policy \
    --output text \
    --policy-name $scale_in_policy \
    --auto-scaling-group-name $as_group_name \
    --scaling-adjustment=-2 \
    --adjustment-type ChangeInCapacity \
    --cooldown $cooldown)

echo put-metric-alarm $low_cpu_alarm_name with arn $arn
aws cloudwatch put-metric-alarm \
    --alarm-name $low_cpu_alarm_name \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 1 \
    --metric-name CPUUtilization \
    --namespace "AWS/EC2" \
    --period 300 \
    --statistic Average \
    --threshold 30 \
    --alarm-actions $arn \
    --dimensions "Name=AutoScalingGroupName,Value=$as_group_name" \
    --unit Percent

echo put-scaling-policy out
arn=$(aws autoscaling put-scaling-policy \
    --output text \
    --policy-name $scale_out_policy \
    --auto-scaling-group-name $as_group_name \
    --scaling-adjustment=2 \
    --adjustment-type ChangeInCapacity \
    --cooldown $cooldown)

echo put-metric-alarm $high_cpu_alarm_name with arn $arn
aws cloudwatch put-metric-alarm \
    --alarm-name $high_cpu_alarm_name \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods  1 \
    --metric-name CPUUtilization \
    --namespace "AWS/EC2" \
    --period 300 \
    --statistic Average \
    --threshold 70 \
    --alarm-actions $arn \
    --dimensions "Name=AutoScalingGroupName,Value=$as_group_name" \
    --unit Percent
