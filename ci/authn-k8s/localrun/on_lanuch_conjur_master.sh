# copy local git diff into cucumber/conjur container just before running
# conjur server

conjur_pod=$(kubectl get pods -l app=conjur-authn-k8s -o=jsonpath='{.items[].metadata.name}')
cucumber_pod=$(kubectl get pods -l app=cucumber-authn-k8s -o=jsonpath='{.items[].metadata.name}')

  if [ -f "/src/localrun/changeset.tar" ]; then
    kubectl cp /src/localrun/changeset.tar $conjur_pod:/tmp
    kubectl exec -i $conjur_pod -- tar -zxvf  /tmp/changeset.tar --directory /opt/conjur-server/

    kubectl cp /src/localrun/changeset.tar $cucumber_pod:/tmp
    kubectl exec -i $cucumber_pod -- tar -zxvf  /tmp/changeset.tar --directory /opt/conjur-server/
  fi

#kubectl exec $conjur_pod -- bash -c "conjurctl server > /tmp/conjurctl.log 2> /tmp/conjurctl.log &"




