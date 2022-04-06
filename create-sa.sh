name=$1
namespace=$2
role=$3
clusterName=$namespace
server=$(kubectl config view --minify | grep server | awk '{ print $2; }')
serviceAccount=$name 
kubectl create -n $namespace sa $serviceAccount
kubectl create -n $namespace clusterrolebinding ${namespace}-${role} --clusterrole ${role} --serviceaccount=$namespace:$serviceAccount --namespace $namespace
set -o errexit
secretName=$(kubectl --namespace $namespace get serviceAccount $serviceAccount -o jsonpath='{.secrets[0].name}')
ca=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.ca\.crt}')
token=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.token}' | base64 --decode)

echo "
---
apiVersion: v1
kind: Config
clusters:
  - name: ${clusterName}
    cluster:      
      certificate-authority-data: ${ca}      
      server: ${server}
contexts:  
  - name: ${serviceAccount}@${clusterName}    
  - context:      
      cluster: ${clusterName}      
      namespace: ${serviceAccount}      
      user: ${serviceAccount}
users:  
  - name: ${serviceAccount}    
    user:      
      token: ${token}
current-context: ${serviceAccount}@${clusterName}" > sa.kubeconfig
