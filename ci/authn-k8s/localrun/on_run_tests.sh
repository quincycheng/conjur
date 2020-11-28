#!/bin/bash -ex

cucumber_pod=$(kubectl get pods -l app=cucumber-authn-k8s -o=jsonpath='{.items[].metadata.name}')
kubectl exec -i $cucumber_pod --  sleep 9999999
