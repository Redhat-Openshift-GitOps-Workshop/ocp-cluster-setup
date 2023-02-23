#
# Wait until the operator $1 is ready. An operator is ready when condition=Ready.
#
waitoperatorpod() {
  NS=openshift-operators
  waitpodup $1 ${NS}
  oc get pods -n ${NS} | grep ${1} | awk '{print "oc wait --for condition=Ready -n '${NS}' pod/" $1 " --timeout 300s"}' | sh
}

#
# Wait until pod $1 is ready
#
waitpodup(){
  x=1
  test=""
  while [ -z "${test}" ]
  do 
    echo "Waiting ${x} times for pod ${1} in ns ${2}" $(( x++ ))
    sleep 1 
    test=$(oc get po -n ${2} | grep ${1})
  done
}

#
# Setup process
#

echo -n "Disable self namespaces provisioner "

oc patch clusterrolebinding.rbac self-provisioners -p '{"subjects": null}'

echo -n "Installing GitOps Operator "

oc apply -f ./scripts/files/redhat_gitops.yaml
echo -n "Waiting for GitOps Operators is ready... "
waitoperatorpod gitops
sleep 30

echo -n "Installation process has finished"