 See my Medium story for more details 

https://medium.com/@ankur.jha/eks-cbb191108a0?sk=57e3988363405be5bc1d24588fcb9c6e

# eks-AWS

### Table of Contents

* [Pre-Requisites](#Pre-requisites)
* [Starting Cluster Creation](#starting-cluster-creation)
  * [Script Steps](#script-steps)
* [Cleanup](#Cleanup)
  * [Delete cluster](#delete-cluster)


# Pre-requisites

* `awscli` ([reference](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html))
* `aws-iam-authenticator` ([reference](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html))
* `eksctl (0.1.18)` ([reference](https://github.com/weaveworks/eksctl))
* `helm` ([reference](https://docs.helm.sh/using_helm/#installing-helm))



<a id="starting-cluster-creation">

# Starting Cluster Creation

To create a cluster start the script deploy.sh

You should especify one environment:
- nonprod
- mgmt
- prod

```shell 
./deploy.sh nonprod|mgmt|prod
```

If you choose the `prod` option, the script will ask to you in which aws region must be placed this new cluster:
- 1) eu-west-1 

<a id="script-steps">

## Next Steps

The script will automatically create the following:

- Update trust relationship roles to k8s nodes role
- Create helm service account
- Apply RBAC to helm service account
- Initialize helm
- Deploy ALB Controller
- Deploy keel


## Get cluster access

To get access to a cluster, use the command:
```shell 
eksctl utils write-kubeconfig --name cluster-name
```


## Deploying Demo

```shell
kubectl apply -f resources/demo.yaml
```
** PS: This demo is using `nonprod` cluster settings, if you want to use in another cluster please remember to change the fields at the ingress section:
- `alb.ingress.kubernetes.io/subnets:  #nonprod DMZ subnets`

- `alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:eu-west-1"
- `- host: www.example.com`

# Cleanup

<a id="delete-cluster">

### Delete cluster
```shell
CLUSTER_NAME="nonprod"
helm delete nginx-ingress --purge
kubectl delete ingress,svc,deployment nginx
eksctl delete cluster --name ${CLUSTER_NAME}
```

