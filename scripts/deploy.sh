#!/bin/bash
# OpsLab - Ansible playbook runner
# Usage: ./deploy.sh [stage]
# Stages: init, lb, web, db, monitor, k8s, all

STAGE="${1:-all}"
PLAYBOOK_DIR="/test-ops/ansible"

case $STAGE in
  init)    ansible-playbook "$PLAYBOOK_DIR/init_servers.yml" ;;
  lb)      ansible-playbook "$PLAYBOOK_DIR/lb_setup.yml" ;;
  web)     ansible-playbook "$PLAYBOOK_DIR/web_setup.yml" ;;
  db)      ansible-playbook "$PLAYBOOK_DIR/db_setup.yml" ;;
  monitor) ansible-playbook "$PLAYBOOK_DIR/monitor_setup.yml" ;;
  k8s)     ansible-playbook "$PLAYBOOK_DIR/k8s_setup.yml" ;;
  all)
    ansible-playbook "$PLAYBOOK_DIR/init_servers.yml"
    ansible-playbook "$PLAYBOOK_DIR/lb_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/web_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/db_setup.yml"
    ansible-playbook "$PLAYBOOK_DIR/monitor_setup.yml"
    ;;
  *)
    echo "Usage: $0 {init|lb|web|db|monitor|k8s|all}"
    exit 1
    ;;
esac
