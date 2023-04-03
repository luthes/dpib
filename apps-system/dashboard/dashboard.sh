# Set Kubeconfig
kubectl -n kube-system port-forward $POD_NAME 8443:8443

# Create Admin Service Account
#kubectl create clusterrolebinding kubernetes-dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
