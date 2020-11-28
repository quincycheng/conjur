#!/bin/bash -ex

cucumber_pod=$(kubectl get pods -l app=cucumber-authn-k8s -o=jsonpath='{.items[].metadata.name}')
kubectl exec -i $cucumber_pod -- ./bin/cucumber K8S_VERSION=1.7 PLATFORM=kubernetes --no-color --format pretty --format junit --out /opt/conjur-server/output -r ./cucumber/kubernetes/features/step_definitions/ -r ./cucumber/kubernetes/features/support/world.rb -r ./cucumber/kubernetes/features/support/hooks.rb -r ./cucumber/kubernetes/features/support/conjur_token.rb --tags ~@skip ./cucumber/kubernetes/features/authenticate.feature:4
#kubectl exec -i $cucumber_pod -- ./bin/cucumber K8S_VERSION=1.7 PLATFORM=kubernetes --no-color --format pretty --format junit --out /opt/conjur-server/output -r ./cucumber/kubernetes/features/step_definitions/ -r ./cucumber/kubernetes/features/support/world.rb -r ./cucumber/kubernetes/features/support/hooks.rb -r ./cucumber/kubernetes/features/support/conjur_token.rb --tags ~@skip ./cucumber/kubernetes/features
