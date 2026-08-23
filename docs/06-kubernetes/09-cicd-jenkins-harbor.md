# CI/CD：Jenkins + Harbor 联动

## 目标
Jenkins 构建镜像 → 推送 Harbor → 触发 K8s 滚动更新。

## 1. Harbor 创建项目
1. 登录 `http://10.0.0.18:30080`（admin / Harbor12345）
2. 新建项目 `ops-app`（公开或私有均可）

## 2. Jenkins 配置凭证
进入 Jenkins → Manage Credentials → Add：

| 类型 | ID | 内容 |
|---|---|---|
| Username with password | `harbor-creds` | admin / Harbor12345 |
| Secret text | `kube-config` | `/root/.kube/config` 的 base64 |

## 3. Jenkinsfile

见 [cicd/Jenkinsfile](../../cicd/Jenkinsfile)，核心三段：

- **Build**：`docker build -t ${IMAGE} .`
- **Push**：`withCredentials(harbor-creds)` → `docker login` + `docker push`
- **Deploy**：`withCredentials(kube-config)` → `kubectl set image` + `rollout status`

## 4. containerd 配置允许 Harbor HTTP（所有 K8s 节点）

配置文件见 [k8s/containerd-harbor-hosts.toml](../../k8s/containerd-harbor-hosts.toml)，部署到：

```
/etc/containerd/certs.d/10.0.0.18:30080/hosts.toml
```

修改后 `systemctl restart containerd`。

## 5. 验证

```bash
# Jenkins 触发构建 → 镜像推送成功
curl -u admin:Harbor12345 http://10.0.0.18:30080/api/v2.0/projects/ops-app/repositories

# Pod 滚动更新
kubectl get pods -w | grep webapp
```
