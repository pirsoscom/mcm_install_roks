

kubectl get clusters --all-namespaces

kubectl delete cluster -n newcluster newcluster
KUBE_EDITOR="nano" kubectl edit cluster -n newcluster newcluster

kubectl get clusters --all-namespaces


kubectl delete cluster -n newcluster newcluster

KUBE_EDITOR="nano" kubectl edit cluster -n newcluster newcluster
