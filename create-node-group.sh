#!/bin/bash

# ---------------------------
# Creating functions
# ---------------------------


function create_node_group(){
eksctl create nodegroup --cluster=${CLUSTER_NAME} \
--name=${NODE_NAME} \
--region=${AWS_REGION} \
--node-labels=${AWS_NODE_LABELS} \
--node-type=${AWS_NODE_TYPE} \
--node-volume-size=${AWS_NODE_VOL} \
--node-ami="ami-id" \
--node-private-networking="true" \
--nodes="2" \
--nodes-min=${AWS_NODE_MIN} \
--nodes-max=${AWS_NODE_MAX} \
--asg-access \
--full-ecr-access \
--external-dns-access
}



echo "create instance group"
echo ""

echo "What is the cluster name? :"
read CLUSTER_NAME
clear

echo "Provide node group name:"
read NODE_NAME
clear

echo "AWS Region:"
read AWS_REGION
clear

echo "Labels, eg: autoscaling=enabled,purpose=project"
read AWS_NODE_LABELS
clear

echo "Instance type:"
read AWS_NODE_TYPE
clear

echo "How many nodes:"
read AWS_NODE_SIZE
clear

echo "ASG min node:"
read AWS_NODE_MIN
clear

echo "AGS max node:"
read AWS_NODE_MAX
clear
        
echo "Creating node group"
create_node_group
