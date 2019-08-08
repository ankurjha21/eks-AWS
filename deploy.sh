#!/bin/bash
# ---------------------------
# USAGE: ./deploy.sh CLUSTER_NAME nonprod|mgmt|prod
# ---------------------------

# ---------------------------
# Starting functions
# ---------------------------
function create_cluster(){
eksctl create cluster --name=${CLUSTER_NAME} \
--tags=${CLUSTER_TAGS} \
--region=${AWS_REGION} \
--vpc-cidr=${AWS_VPC_CIDR} \
--vpc-private-subnets=${AWS_PRIVATE_SUBNETS} \
--vpc-public-subnets=${AWS_PUBLIC_SUBNETS} \
--nodegroup-name=${AWS_NODE_NAME} \
--node-labels=${AWS_NODE_LABELS} \
--node-type=${AWS_NODE_TYPE} \
--node-volume-size=${AWS_NODE_VOL} \
--node-ami=${AWS_NODE_AMI} \
--node-private-networking="true" \
--nodes=${AWS_NODE_SIZE} \
--nodes-min=${AWS_NODE_MIN} \
--nodes-max=${AWS_NODE_MAX} \
--asg-access \
--full-ecr-access 
}

function iam_attach(){
    #aws iam list-roles --output json --query "Roles[?contains(RoleName, 'eksctl-nonprod-nodegroup-core-NodeInstanceRole')]" | jq ".[].Arn" | xargs
    ROLE_NAME=$(aws iam list-roles | grep -A2 "RoleName" | grep eksctl-${CLUSTER_NAME}-nodegroup | grep arn | sed -e 's/"Arn"://g' | sed -e 's/ //g' | sed -e 's/,//g' | sed -e 's/"//g')
    cat resources/iam-trust-relationship.json | sed -e "s|AWS_ARN|$ROLE_NAME|g" > temp-trust.json
    aws iam update-assume-role-policy --role-name k8s-alb-controller-${CLUSTER_NAME} --policy-document file://temp-trust.json
    aws iam update-assume-role-policy --role-name external-dns-${CLUSTER_NAME} --policy-document file://temp-trust.json
    aws iam update-assume-role-policy --role-name keel-deployment-${CLUSTER_NAME} --policy-document file://temp-trust.json
    rm temp-trust.json
}

function deploy_helm(){
    kubectl create serviceaccount tiller --namespace kube-system  
    kubectl apply -f resources/tiller-rbac.yaml
    helm init --service-account tiller --upgrade
    #sleep 30
    #helm install stable/nginx-ingress --name nginx-ingress --namespace kube-system \
    #--set controller.stats.enabled=true \
    #--set controller.metrics.enabled=true \
    #--set controller.replicaCount=1 \
    #--set rbac.create=true \
    #--set controller.publishService.enabled=true
}

function deploy_alb_controller(){
    cat resources/alb-controller.yaml | \
    sed 's/\${CLUSTER_NAME}'"/${CLUSTER_NAME}/g" | \
    kubectl apply -f -
}

function deploy_externaldns(){
    cat resources/external-dns.yaml | \
    sed 's/\${CLUSTER_NAME}'"/${CLUSTER_NAME}/g" | \
    kubectl apply -f -

    kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
}

function deploy_kube2iam(){
    kubectl apply -f resources/kube2iam.yaml
}

function deploy_keel(){
    cat resources/keel-deployment-rbac.yaml | \
    sed 's/\${CLUSTER_NAME}'"/${CLUSTER_NAME}/g" | \
    kubectl apply -f -
}

function deploy_users(){
    kubectl patch configmap aws-auth -n kube-system --type merge --patch "$(cat resources/users.json)"
}

function initial_menu(){
echo -e '''
USAGE: ./deploy.sh CLUSTER_NAME nonprod|mgmt|prod
'''
}

# ---------------------------
# Starting script
# ---------------------------

case ${1} in

# ---------------------------
# ENVIRONMENTS
# ---------------------------
    mgmt|nonprod)
        echo "Creating ${1} cluster..."
        source environments/${1}/eu-west-1-ireland.sh
        create_cluster
        echo ""

        echo "Applying IAM Roles"
        iam_attach
        echo ""

        echo "Deploying Kube2IAM"
        deploy_kube2iam
        echo ""

        echo "Deploying Ingress NGINX Controller"
        deploy_helm
        echo ""

        echo "Deploying ALB Controler"
        deploy_alb_controller
        echo ""

        #echo "Deploying ExternalDNS"
        #deploy_externaldns
        #echo ""

        echo "Deploying keel"
        deploy_keel
        echo ""

        echo "Apply CSTeam users"
        deploy_users
        echo ""

        echo "Done!"
        exit 0
    ;;

    prod)
        echo -e ''' 
        Choose one Region:
        1) eu-west-1 Ireland
        2) us-east-1 North Virginia
        3) ap-northeast-1 Tokyo
        4) ap-southeast-2 Sydney
        '''
        read OPT
        clear

        echo "Creating Prod cluster ..."
        source environments/prod/${OPT}.sh
        create_cluster
        echo ""

        echo "Applying IAM Roles"
        iam_attach
        echo ""

        echo "Deploying Kube2IAM"
        deploy_kube2iam
        echo ""

        echo "Deploying Ingress NGINX Controller"
        deploy_helm
        echo ""

        echo "Deploying ALB Controler"
        deploy_alb_controller
        echo ""

        #echo "Deploying ExternalDNS"
        #deploy_externaldns
        #echo ""

        echo "Deploying keel"
        deploy_keel
        echo ""

        echo "Apply  users"
        deploy_users
        echo ""

        echo "Done!"
        exit 0

    ;;

    *)
        echo "Option ${1} not found, try again"
        initial_menu
    ;;
esac
