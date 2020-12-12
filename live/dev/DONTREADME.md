# Kube


## install kube dashboard
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
kubectl delete clusterrolebinding kubernetes-dashboard
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard --user=clusterUser


```
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
``


# wireguard on Kube

https://hub.docker.com/r/masipcat/wireguard-go
https://place1.github.io/wg-access-server/
https://kilo.squat.ai/docs/vpn-server/
https://github.com/mjtechguy/wireguard-site-to-site
https://gist.github.com/insdavm/b1034635ab23b8839bf957aa406b5e39
https://www.strongswan.org/testing/testresults/swanctl/rw-cert/




---------------Less important resources
https://itnext.io/azure-kubernetes-service-handling-the-custom-private-dns-zone-for-private-clusters-8f0a79f2efc2
https://severalnines.com/database-blog/multi-cloud-deployment-mariadb-replication-using-wireguard
https://github.com/Azure/terraform-azurerm-network-security-group
-----------------------

apiVersion: v1
kind: Service
metadata:
  name: public-svc
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: public-app