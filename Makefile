# =============================================================================
# OpsLab - 常用任务统一入口
# 用法：make <target>   （查看所有目标：make help）
# =============================================================================
SHELL := /bin/bash
.DEFAULT_GOAL := help

# 可选参数：
#   make backup DB=opslab
#   make deploy STAGE=web
#   make docker-build TAG=v1.0
DB     ?=
STAGE  ?= help
TAG    ?= latest

.PHONY: help check backup deploy docker-build k8s-apply validate

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

check: ## 运行集群健康检查（scripts/check.sh）
	@scripts/check.sh

backup: ## 备份 MySQL 数据库（DB 指定库，默认 opslab）
	@scripts/backup.sh $(DB)

deploy: ## 部署指定阶段（STAGE 指定，如 make deploy STAGE=web）
	@scripts/deploy.sh $(STAGE)

docker-build: ## 构建应用镜像（TAG 指定版本，默认 latest）
	@docker build -f docker/Dockerfile -t harbor.opslab.local/opslab/web-app:$(TAG) .

k8s-apply: ## 应用 K8s 中间件清单（Redis/Jenkins/ES）
	@kubectl apply -f k8s/redis_master_slave.yaml
	@kubectl apply -f k8s/jenkins.yaml
	@kubectl apply -f k8s/es_kibana.yaml

validate: ## 校验脚本语法（bash -n）与 PHP 语法（php -l）
	@for f in scripts/*.sh; do bash -n "$$f" && echo "OK  $$f"; done
	@php -l app/index.php
	@php -l app/health.php
