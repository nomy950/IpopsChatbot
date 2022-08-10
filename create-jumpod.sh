#!/usr/bin/env bash
##
## =============================================================================
## IBM Confidential
## © Copyright IBM Corp. 2021
##
## The source code for this program is not published or otherwise divested of
## its trade secrets, irrespective of what has been deposited with the
## U.S. Copyright Office.
## =============================================================================
##

# Used to create jumpod for IPOPS

JUMPOD="jumpod-ipops-$(date +%s)"
CLUSTER=$(kubectl config current-context)
TOKEN=$(kubectl -n rias get secret regional-extension-server-client-kubeconfig -o yaml | grep 'kubeconfig:' | awk '{print $2}' | base64 -d |grep token | awk '{print $2}')

USER1=${USER/@/.}

GREEN="\x1b[38;5;121m"
YELLOW="\x1b[38;5;226m"
RED="\x1b[38;5;124m"
NC="\x1b[0m"

VERBOSE=false;
FROM_FILE="";

get_config() {
# Create jumpod deploy
cat <<EOF > jumpod-deploy.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: ${JUMPOD}
  namespace: rias
  labels:
    app: jumpod-ipops
    user: ${USER1%%.*}
spec:
  containers:
  - image: ubuntu:latest
    imagePullPolicy: IfNotPresent
    name: ${JUMPOD}
    stdin: true
    tty: true
    env:
    - name: KUBECONFIG
      value: /etc/regional-extension-server-client-kubeconfig/kubeconfig
    volumeMounts:
    - mountPath: /etc/regional-extension-server-client-kubeconfig
      name: regional-extension-server-client-kubeconfig
  restartPolicy: Always
  volumes:
  - name: regional-extension-server-client-kubeconfig
    secret:
      defaultMode: 420
      items:
      - key: kubeconfig
        path: kubeconfig
      secretName: regional-extension-server-client-kubeconfig
EOF

# Create jumpod kube-config
cat <<EOF > ${JUMPOD}-config
---
apiVersion: v1
kind: Config
clusters:
- name: regional-extension-server
  cluster:
    insecure-skip-tls-verify: true
    server: https://regional-extension-server.rias.svc:6443
users:
- name: rias
  user:
    token: ${TOKEN}
contexts:
- name: rias
  context:
    cluster: regional-extension-server
    user: rias
current-context: "rias"
EOF

# Pkginstall
cat <<'EOF' > pkginstall
apt-get -qq update > /dev/null
apt-get install curl vim jq git -y -qq > /dev/null
mkdir -p ~/.kube/bin
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

EOF

cat <<'EOF' > dotfile
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
EOF
}

setup_jumpod() {
  kubectl cp pkginstall rias/${JUMPOD}:/root/pkginstall
  kubectl cp dotfile rias/${JUMPOD}:/root/dotfile
  kubectl exec -n rias ${JUMPOD} -- bash /root/pkginstall > /dev/null 2>&1
  kubectl cp ${JUMPOD}-config rias/${JUMPOD}:/root/.kube/config
  kubectl exec -n rias ${JUMPOD} -- bash /root/dotfile
}

clean_files() {
  if [ "$VERBOSE" = true ];
  then
    echo -e "${YELLOW} Deleting jumpod ......${NC}"
  fi

  rm -f ${JUMPOD}-config pkginstall dotfile jumpod-deploy.yaml

  if [ "$VERBOSE" = true ];
  then
    kubectl -n rias delete pod ${JUMPOD}
    echo -e "${GREEN} Done ${NC}"
  else
    kubectl -n rias delete pod ${JUMPOD} > /dev/null 2>&1
  fi
}

check_status() {
  { STATUS=$(kubectl -n rias get po |grep ${JUMPOD} | grep Running); sleep 3; } &
  while kill -0 "$!" > /dev/null 2>&1; do
    if [ "$VERBOSE" = true ];
    then
      pro_bar "Waiting for jumpod running";
    fi;
  done
}

pro_bar() {
      local i DOTS
      echo -en "${YELLOW} $1        ${NC}\r"
      DOTS=""

      for (( i=1; i<7; i++ ));
      do DOTS="${DOTS}."
        echo -en "${YELLOW} $1 ${DOTS} ${NC}\r"
	sleep .5
      done
}

commands_from_file() {

  export FROM_FILE=$1;

  if [ ! -f "$FROM_FILE" ];
  then
    echo "File $1 does not exist. Stopping...";
    exit;
  fi;

  perms=$(stat -c %A $FROM_FILE | cut -c 4);

  if [ "$perms" != "x" ];
  then
    echo "Correcting file $1 permissions";
    chmod u+x $FROM_FILE;
  fi
}

main() {

  while getopts :c:f:v flag
  do
    case "${flag}" in
      c) runcommand=${OPTARG} ;;
      f) commands_from_file ${OPTARG};;
      v) export VERBOSE=true;;
      *) echo "Invalid option: -$flag" ;;
    esac
  done

  trap clean_files EXIT

  if [ "$VERBOSE" = true ];
  then
    echo -e " Will create ${GREEN}${JUMPOD}${NC} on ${GREEN}${CLUSTER} ${NC}..."
  fi;

  get_config

  if [ "$VERBOSE" = true ];
  then
    kubectl -n rias apply -f jumpod-deploy.yaml
  else
    kubectl -n rias apply -f jumpod-deploy.yaml > /dev/null 2>&1
  fi;

  check_status
  setup_jumpod

  if [ ! -z "$runcommand" ];
  then
    kubectl -n rias exec -it ${JUMPOD} -- $runcommand
  elif  [ -f "$FROM_FILE" ];
  then
    kubectl cp $FROM_FILE rias/${JUMPOD}:/root/commands_from_file
    kubectl -n rias exec -it ${JUMPOD} -- bash -c /root/commands_from_file
  else
     kubectl -n rias exec -it ${JUMPOD} -- bash
  fi;
}

main "$@"
