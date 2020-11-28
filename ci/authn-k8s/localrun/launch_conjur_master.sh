conjur_pod=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')
kubectl exec -i $conjur_pod -- conjurctl server
