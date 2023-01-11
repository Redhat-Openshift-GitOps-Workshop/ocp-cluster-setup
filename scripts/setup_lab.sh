#
# Wait until the operator $1 is ready. An operator is ready when condition=Ready.
#
waitoperatorpod() {
  NS=openshift-operators
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

#
# Setup process
#

echo -n "Generate users credentials"

htpasswd -c -b users.htpasswd admin admin
htpasswd -b users.htpasswd developer developer

echo -n "Creating htpasswd secrets in Openshift"

oc delete secret lab-users -n openshift-config
oc create secret generic lab-users --from-file=htpasswd=users.htpasswd -n openshift-config

echo -n "Configuring OAuth to authenticate users via htpasswd"

oc apply -f ./scripts/files/oauth.yaml

echo -n "Disable self namespaces provisioner"

oc patch clusterrolebinding.rbac self-provisioners -p '{"subjects": null}'

echo -n "Creating Role Binding for admin user"

oc adm policy add-cluster-role-to-user admin admin

echo -n "Installing GitOps Operator"

oc apply -f ./scripts/files/redhat_gitops.yaml
echo -n "Waiting for GitOps Operators is ready..."
waitoperatorpod gitops
sleep 30

echo -n "Installing Bitnami Sealed Secret"

helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets/
helm install gitops-sealed-secret bitnami-labs/sealed-secrets --version 2.7.1
sleep 30

echo -n "Configuring ArgoCD Service Account in order to create Bitnami Sealed Secret resources"
oc apply -f ./scripts/files/sealed-secret-custom-role.yaml