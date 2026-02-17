# 🎓 CKAD学習用フルスタックKubernetesプロジェクト

> **Certified Kubernetes Application Developer (CKAD)** の出題範囲を実践的に学ぶための、GitOps対応フルスタック教材プロジェクトです。

---

## 📖 目次

1. [アーキテクチャ](#アーキテクチャ)
2. [技術スタック](#技術スタック)
3. [CKAD資格概要](#ckad資格概要)
4. [この教材での学習内容](#この教材での学習内容)
5. [ディレクトリ構成](#ディレクトリ構成)
6. [環境構築手順](#環境構築手順)
7. [推奨書籍・学習リソース](#推奨書籍学習リソース)
8. [トラブルシューティング](#トラブルシューティング)

---

## アーキテクチャ

### システム全体構成図

```mermaid
graph TB
    subgraph "開発者のローカルマシン"
        DEV[開発者] -->|git push| GIT[Git Repository]
    end

    subgraph "Minikube Cluster"
        subgraph "Ingress Layer"
            ING[Ingress Controller<br/>NGINX]
        end

        subgraph "Application Layer"
            FE[Frontend<br/>React/Next.js<br/>TypeScript]
            BE[Backend<br/>Go REST API<br/>OpenTelemetry計装]
        end

        subgraph "Data Layer"
            DB[(MongoDB<br/>StatefulSet)]
        end

        subgraph "GitOps Layer"
            ARGO[ArgoCD<br/>GitOps Controller]
        end

        subgraph "Observability Layer"
            PROM[Prometheus<br/>メトリクス収集]
            GRAF[Grafana<br/>可視化ダッシュボード]
            ALERT[Alertmanager<br/>アラート通知]
            OTEL[OpenTelemetry<br/>Collector]
        end

        subgraph "Security Layer"
            CERT[cert-manager<br/>TLS証明書管理]
        end
    end

    USER[User] -->|HTTPS| ING
    ING -->|/| FE
    ING -->|/api| BE
    BE -->|CRUD| DB
    BE -->|traces| OTEL
    OTEL -->|metrics| PROM
    PROM -->|datasource| GRAF
    PROM -->|alerts| ALERT
    GIT -->|sync| ARGO
    ARGO -->|deploy| FE
    ARGO -->|deploy| BE
    CERT -->|TLS| ING

    style ARGO fill:#f96,stroke:#333
    style PROM fill:#e6522c,stroke:#333,color:#fff
    style GRAF fill:#f46800,stroke:#333,color:#fff
    style FE fill:#61dafb,stroke:#333
    style BE fill:#00add8,stroke:#333,color:#fff
    style DB fill:#4db33d,stroke:#333,color:#fff
```

### リクエストフロー

```mermaid
sequenceDiagram
    participant U as User
    participant I as Ingress (NGINX)
    participant F as Frontend (React)
    participant B as Backend (Go)
    participant D as MongoDB
    participant O as OpenTelemetry
    participant P as Prometheus

    U->>I: HTTPS リクエスト
    I->>F: / (静的ファイル配信)
    F->>I: /api/* (API呼び出し)
    I->>B: /api/* (リバースプロキシ)
    B->>D: CRUD操作
    D-->>B: レスポンス
    B->>O: トレース送信
    O->>P: メトリクス転送
    B-->>I: JSONレスポンス
    I-->>F: データ返却
    F-->>U: UI更新
```

### 技術スタック選定理由

| 技術 | 役割 | 選定理由 |
|------|------|----------|
| **Helmfile** | マニフェスト管理 | 複数のHelmリリースを宣言的に一元管理でき、環境差分(dev/staging/prod)を`values`で切り替え可能。`helmfile sync`一発で全コンポーネントを構築できる。 |
| **ArgoCD** | GitOpsデプロイ | Gitリポジトリをsingle source of truthとし、宣言的にクラスタ状態を同期。CKADでも実務でも必須のGitOps知識が身につく。 |
| **Prometheus + Grafana** | 監視・可視化 | Kubernetesエコシステムの標準的な監視スタック。CKADの「Observability」セクションの学習に直結。 |
| **OpenTelemetry** | 分散トレーシング | ベンダー非依存のオブザーバビリティフレームワーク。業界標準として今後のデファクトスタンダード。 |
| **cert-manager** | 証明書管理 | Kubernetes上でのTLS証明書の自動発行・更新を担当。Security関連の学習に最適。 |
| **MongoDB** | データベース | StatefulSetやPersistent Volumeの実践的な学習に最適。NoSQLのためスキーマ変更が容易で学習向き。 |
| **Minikube** | ローカルK8s | Windows/Mac/LinuxのクロスプラットフォームでKubernetesクラスタを手軽に構築。Ingress Addonなど学習に便利な機能が豊富。 |

---

## 技術スタック

| カテゴリ | 技術 | バージョン目安 |
|----------|------|--------------|
| Frontend | React (Vite + TypeScript) | React 18+ |
| Backend | Go (Golang) | Go 1.22+ |
| Database | MongoDB | 7.0+ |
| Container Runtime | Docker / Containerd | - |
| Orchestration | Kubernetes (Minikube) | v1.29+ |
| Package Manager | Helm / Helmfile | Helm 3.14+, Helmfile 0.160+ |
| GitOps | ArgoCD | v2.10+ |
| Monitoring | Prometheus, Grafana | - |
| Tracing | OpenTelemetry | - |
| Alerting | Alertmanager | - |
| Security | cert-manager | v1.14+ |

---

## CKAD資格概要

### CKADとは？

**Certified Kubernetes Application Developer (CKAD)** は、The Linux Foundation と Cloud Native Computing Foundation (CNCF) が共同で提供するKubernetes認定資格です。

Kubernetesクラスタ上でクラウドネイティブアプリケーションを**設計・構築・デプロイ・管理**する能力を証明します。

### 対象者

- Kubernetesアプリケーション開発者
- クラウドネイティブアプリケーションエンジニア
- DevOpsエンジニア
- ソフトウェアエンジニア（コンテナ/K8sを使用する方）

### 推奨される前提知識

- Dockerコンテナの基本的な理解
- YAML記法への慣れ
- Linux基本操作（CLI操作）
- いずれかのプログラミング言語の経験

### 試験形式

| 項目 | 詳細 |
|------|------|
| **試験形式** | パフォーマンスベース（実技試験） |
| **試験時間** | **2時間** |
| **問題数** | 15〜20問程度 |
| **合格ライン** | **66%以上** |
| **受験料** | $395 USD（再受験1回無料） |
| **有効期間** | 取得から**3年間** |
| **試験環境** | ブラウザベースのターミナル操作 |
| **Kubernetesバージョン** | 試験時点の最新安定版マイナー2つ以内 |
| **使用可能リソース** | kubernetes.io公式ドキュメントのみ参照可 |
| **言語** | 英語 |

### 出題範囲（2024年改定版）

| ドメイン | 出題比率 |
|----------|----------|
| Application Design and Build | 20% |
| Application Deployment | 20% |
| Application Observability and Maintenance | 15% |
| Application Environment, Configuration and Security | 25% |
| Services and Networking | 20% |

### 試験対策のポイント

1. **時間管理が最重要**: 2時間で15〜20問を解く必要があるため、1問あたり6〜8分が目安
2. **`kubectl`コマンドの習熟**: 特に `kubectl run`, `kubectl create`, `kubectl expose` などのimperativeコマンドを素早く打てること
3. **エイリアスの設定**: 試験冒頭で `alias k=kubectl` や `export do="--dry-run=client -o yaml"` を設定
4. **公式ドキュメントの検索力**: kubernetes.io から素早く必要な情報を見つけるスキル
5. **実機演習の反復**: 本プロジェクトのような実践環境での反復練習が合格への近道

---

## この教材での学習内容

### CKADドメインとプロジェクト構成の対応表

| CKADドメイン | 学習内容 | 対応ディレクトリ/ファイル |
|-------------|---------|----------------------|
| **Application Design and Build** | | |
| - コンテナイメージの定義 | Dockerfile作成・マルチステージビルド | `backend/Dockerfile`, `frontend/Dockerfile` |
| - Pod設計パターン | Init Container, Sidecar, Multi-container Pod | `k8s/charts/backend/templates/deployment.yaml` |
| - Job / CronJob | DBバックアップジョブ、バッチ処理 | `k8s/charts/backend/templates/cronjob.yaml` |
| - Persistent Volume | MongoDBのデータ永続化 | `k8s/charts/mongodb/templates/statefulset.yaml` |
| **Application Deployment** | | |
| - Deployment戦略 | RollingUpdate, Blue/Green | `k8s/charts/*/templates/deployment.yaml` |
| - Helm Charts | カスタムChart作成とテンプレート化 | `k8s/charts/` |
| - GitOps | ArgoCDによる自動デプロイ | `k8s/argocd/` |
| **Application Observability and Maintenance** | | |
| - Liveness/Readiness Probe | ヘルスチェック設定 | `k8s/charts/backend/templates/deployment.yaml` |
| - ログ・メトリクス収集 | Prometheus + OpenTelemetry | `backend/` (計装コード), `k8s/helmfile/` |
| - Grafanaダッシュボード | 可視化設定 | Helmfileで自動構築 |
| **Application Environment, Configuration and Security** | | |
| - ConfigMap / Secret | 環境変数・設定ファイル管理 | `k8s/charts/*/templates/configmap.yaml`, `secret.yaml` |
| - SecurityContext | コンテナセキュリティ設定 | `k8s/charts/*/templates/deployment.yaml` |
| - ServiceAccount | RBAC設定 | `k8s/charts/*/templates/serviceaccount.yaml` |
| - ResourceQuota / LimitRange | リソース制限 | `k8s/charts/*/templates/deployment.yaml` |
| - cert-manager | TLS証明書の自動管理 | `k8s/helmfile/` |
| **Services and Networking** | | |
| - Service (ClusterIP/NodePort/LB) | サービスディスカバリ | `k8s/charts/*/templates/service.yaml` |
| - Ingress | 外部公開・ルーティング | `k8s/charts/*/templates/ingress.yaml` |
| - NetworkPolicy | ネットワーク制限 | `k8s/charts/*/templates/networkpolicy.yaml` |

### 学習の進め方

```
Step 1: 環境構築 (setup.sh / setup.ps1)
    ↓
Step 2: アプリケーションコード理解 (backend/, frontend/)
    ↓
Step 3: Dockerfile・コンテナビルド理解
    ↓
Step 4: Helm Chart構造の理解 (k8s/charts/)
    ↓
Step 5: Helmfileによる一括デプロイ (k8s/helmfile/)
    ↓
Step 6: ArgoCDでGitOpsフロー体験 (k8s/argocd/)
    ↓
Step 7: Observability確認 (Prometheus/Grafana)
    ↓
Step 8: 模擬問題に挑戦
```

---

## ディレクトリ構成

```
study-ckad/
├── README.md                          # 本ファイル
├── backend/                           # Go APIサーバー
│   ├── Dockerfile                     # マルチステージビルド
│   ├── go.mod
│   ├── go.sum
│   ├── main.go                        # エントリーポイント
│   ├── handler/                       # HTTPハンドラー
│   │   └── task.go
│   ├── model/                         # データモデル
│   │   └── task.go
│   └── db/                            # DB接続
│       └── mongo.go
├── frontend/                          # React (TypeScript)
│   ├── Dockerfile
│   ├── nginx.conf                     # 本番用Nginx設定
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── index.html
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── App.css
│       ├── api/
│       │   └── tasks.ts               # APIクライアント
│       └── components/
│           ├── TaskList.tsx
│           └── TaskForm.tsx
├── k8s/                               # Kubernetes設定
│   ├── charts/                        # カスタムHelm Charts
│   │   ├── backend/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── _helpers.tpl
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── ingress.yaml
│   │   │       ├── configmap.yaml
│   │   │       ├── secret.yaml
│   │   │       ├── serviceaccount.yaml
│   │   │       ├── hpa.yaml
│   │   │       ├── networkpolicy.yaml
│   │   │       └── cronjob.yaml
│   │   ├── frontend/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── _helpers.tpl
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── ingress.yaml
│   │   │       ├── configmap.yaml
│   │   │       └── serviceaccount.yaml
│   │   └── mongodb/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── _helpers.tpl
│   │           ├── statefulset.yaml
│   │           ├── service.yaml
│   │           ├── secret.yaml
│   │           └── pvc.yaml
│   ├── helmfile/                      # Helmfile設定
│   │   ├── helmfile.yaml              # メイン定義
│   │   └── values/
│   │       ├── argocd.yaml
│   │       ├── prometheus.yaml
│   │       ├── grafana.yaml
│   │       ├── cert-manager.yaml
│   │       └── mongodb.yaml
│   └── argocd/                        # ArgoCD Application定義
│       ├── project.yaml
│       ├── app-backend.yaml
│       ├── app-frontend.yaml
│       └── app-mongodb.yaml
└── scripts/                           # セットアップスクリプト
    ├── setup.sh                       # macOS / Linux用
    └── setup.ps1                      # Windows PowerShell用
```

---

## 環境構築手順

### 前提条件

以下のツールがインストールされていることを確認してください。

| ツール | インストール方法 (macOS) | インストール方法 (Windows) |
|--------|------------------------|--------------------------|
| Docker | `brew install --cask docker` | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Minikube | `brew install minikube` | `choco install minikube` |
| kubectl | `brew install kubectl` | `choco install kubernetes-cli` |
| Helm | `brew install helm` | `choco install kubernetes-helm` |
| Helmfile | `brew install helmfile` | `choco install helmfile` |

### クイックスタート

#### macOS / Linux

```bash
# リポジトリをクローン
git clone <YOUR_REPO_URL> study-ckad
cd study-ckad

# セットアップスクリプト実行
chmod +x scripts/setup.sh
./scripts/setup.sh
```

#### Windows (PowerShell)

```powershell
# リポジトリをクローン
git clone <YOUR_REPO_URL> study-ckad
cd study-ckad

# セットアップスクリプト実行
.\scripts\setup.ps1
```

### 手動でのステップバイステップ構築

```bash
# 1. Minikube起動
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Ingressアドオン有効化
minikube addons enable ingress
minikube addons enable metrics-server

# 3. Minikubeの Docker 環境を利用
eval $(minikube docker-env)

# 4. アプリケーションイメージのビルド
docker build -t study-ckad-backend:latest ./backend
docker build -t study-ckad-frontend:latest ./frontend

# 5. Helmfileで全コンポーネントをデプロイ
cd k8s/helmfile
helmfile sync

# 6. ArgoCD Application定義の適用
kubectl apply -f ../argocd/

# 7. ArgoCD UIアクセス
# 初期パスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# ポートフォワード
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# 8. Grafana UIアクセス
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 &

# 9. アプリケーションへアクセス
# Minikube IP確認
minikube ip
# ブラウザで http://<MINIKUBE_IP>/ にアクセス
```

---

## 推奨書籍・学習リソース

### 📚 日本語推奨書籍

#### 1. 『Kubernetes完全ガイド 第2版』（青山真也 著 / インプレス）

> **Kubernetes学習のバイブル的存在**

- Kubernetesの基本概念からProduction運用まで網羅的にカバー
- Workload（Pod, Deployment, StatefulSet等）、Service、Ingressなど全リソースを体系的に解説
- 実務で遭遇する細かいオプションや設定パターンも丁寧に説明
- **推奨理由**: CKAD受験者が辞書的に使える一冊。出題範囲のほぼ全てを本書でカバーできる。

#### 2. 『Docker/Kubernetes実践コンテナ開発入門 改訂新版』（山田明憲 著 / 技術評論社）

> **コンテナ技術の基礎から実践までのステップアップ教材**

- Docker基礎 → Docker Compose → Kubernetes と段階的に学べる構成
- 実際のアプリケーション開発フローに沿った実践的な内容
- CI/CDパイプラインの構築方法も解説
- **推奨理由**: Kubernetes以前のDocker基礎が不安な方に最適。コンテナ技術全体の土台を固められる。

#### 3. 『Kubernetesで実践するクラウドネイティブDevOps』（John Arundel, Justin Domingus 著 / オライリー・ジャパン）

> **運用視点でのKubernetes活用術**

- Kubernetesクラスタの運用・管理に焦点を当てた実践書
- Helm、Prometheus、セキュリティなど運用に必要なエコシステムを広くカバー
- GitOps、CI/CDのベストプラクティスを紹介
- **推奨理由**: 本プロジェクトで扱うHelmfile・ArgoCD・Prometheusなどのエコシステムを理解する上で最適。

#### 4. 『CKA/CKADの基礎 ― Kubernetesの基本についてひととおり学べる本 ―』（インプレス / とことんDevOps）

> **CKAD試験に特化した対策本**

- CKA/CKAD試験の出題傾向を踏まえた解説
- 模擬問題と解答で実践的な試験対策
- `kubectl`コマンドの効率的な使い方を重点解説
- **推奨理由**: 試験直前の仕上げに最適。実際の試験形式に慣れるための必携書。

### 🌐 オンラインリソース

| リソース | URL | 説明 |
|----------|-----|------|
| Kubernetes公式ドキュメント | https://kubernetes.io/ja/docs/ | 試験中に参照可能。日本語訳あり |
| Killer.sh | https://killer.sh | CKAD模擬試験（受験チケットに付属） |
| KodeKloud | https://kodekloud.com | 実践課題付きオンライン学習 |
| CKAD Exercises (GitHub) | https://github.com/dgkanatsios/CKAD-exercises | 無料の練習問題集 |

---

## トラブルシューティング

### よくある問題

<details>
<summary>Minikubeが起動しない</summary>

```bash
# Dockerが起動しているか確認
docker info

# 既存のMinikubeを削除して再作成
minikube delete
minikube start --cpus=4 --memory=8192 --driver=docker
```
</details>

<details>
<summary>Helmfileコマンドが見つからない</summary>

```bash
# macOS
brew install helmfile

# helm-diffプラグインのインストール（Helmfile依存）
helm plugin install https://github.com/databus23/helm-diff
```
</details>

<details>
<summary>ArgoCDのパスワードが取得できない</summary>

```bash
# ArgoCDがデプロイされているか確認
kubectl get pods -n argocd

# Secretの存在確認
kubectl get secret -n argocd

# パスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```
</details>

<details>
<summary>Podが起動しない（ImagePullBackOff）</summary>

```bash
# Minikubeの Docker 環境でイメージをビルドしているか確認
eval $(minikube docker-env)
docker images | grep study-ckad

# イメージを再ビルド
docker build -t study-ckad-backend:latest ./backend
docker build -t study-ckad-frontend:latest ./frontend
```
</details>

---

## ライセンス

このプロジェクトは教育目的で作成されています。自由にフォーク・改変してご利用ください。

---

> 💡 **Tip**: 学習の際は、各Helm Chartのテンプレートファイルを手動で修正して`helmfile sync`を実行してみましょう。ArgoCDがGitの変更を検知して自動同期する様子を観察することで、GitOpsの本質を体感できます。
