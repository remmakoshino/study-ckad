#!/usr/bin/env bash
# ==============================================
# CKAD学習用プロジェクト セットアップスクリプト
# 対象OS: macOS / Linux
# ==============================================
set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║  🎓 CKAD Study Project - Setup Script       ║"
echo "║  Kubernetes Full-Stack Learning Environment  ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ------------------------------------------
# 1. 必須ツールのチェック
# ------------------------------------------
echo -e "${YELLOW}[1/6] 必須ツールの確認...${NC}"

check_command() {
    local cmd=$1
    local install_hint=$2
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}✗ ${cmd} が見つかりません${NC}"
        echo -e "  インストール方法: ${install_hint}"
        return 1
    else
        local version
        version=$($cmd version --short 2>/dev/null || $cmd version --client -o yaml 2>/dev/null | head -1 || $cmd --version 2>/dev/null | head -1 || echo "unknown")
        echo -e "${GREEN}✓ ${cmd} が見つかりました${NC} (${version})"
        return 0
    fi
}

MISSING=0

check_command "docker" "brew install --cask docker (macOS) / sudo apt install docker.io (Linux)" || MISSING=1
check_command "minikube" "brew install minikube (macOS) / https://minikube.sigs.k8s.io/docs/start/" || MISSING=1
check_command "kubectl" "brew install kubectl (macOS) / sudo snap install kubectl --classic (Linux)" || MISSING=1
check_command "helm" "brew install helm (macOS) / https://helm.sh/docs/intro/install/" || MISSING=1
check_command "helmfile" "brew install helmfile (macOS) / https://github.com/helmfile/helmfile/releases" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
    echo -e "\n${RED}必須ツールが不足しています。上記のインストール方法を参考にインストールしてください。${NC}"
    exit 1
fi

echo -e "${GREEN}全ての必須ツールが利用可能です！${NC}\n"

# ------------------------------------------
# 2. Helm Diff プラグインのインストール
# ------------------------------------------
echo -e "${YELLOW}[2/6] Helm Diff プラグインの確認...${NC}"

if ! helm plugin list | grep -q "diff"; then
    echo "helm-diff プラグインをインストール中..."
    helm plugin install https://github.com/databus23/helm-diff
    echo -e "${GREEN}✓ helm-diff プラグインをインストールしました${NC}"
else
    echo -e "${GREEN}✓ helm-diff プラグインは既にインストール済みです${NC}"
fi
echo ""

# ------------------------------------------
# 3. Minikubeの起動
# ------------------------------------------
echo -e "${YELLOW}[3/6] Minikubeクラスタの起動...${NC}"

MINIKUBE_STATUS=$(minikube status -f '{{.Host}}' 2>/dev/null || echo "Stopped")

if [ "$MINIKUBE_STATUS" = "Running" ]; then
    echo -e "${GREEN}✓ Minikubeは既に起動しています${NC}"
else
    echo "Minikubeを起動します（CPUs: 4, Memory: 8GB）..."
    minikube start --cpus=4 --memory=8192 --driver=docker
    echo -e "${GREEN}✓ Minikubeが起動しました${NC}"
fi

# Addon有効化
echo "Minikube Addonを有効化中..."
minikube addons enable ingress 2>/dev/null || true
minikube addons enable metrics-server 2>/dev/null || true
echo -e "${GREEN}✓ Addon（ingress, metrics-server）が有効化されました${NC}\n"

# ------------------------------------------
# 4. コンテナイメージのビルド
# ------------------------------------------
echo -e "${YELLOW}[4/6] コンテナイメージのビルド...${NC}"

# MinikubeのDocker環境を使用
eval $(minikube docker-env)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Backend イメージをビルド中..."
docker build -t study-ckad-backend:latest "$PROJECT_ROOT/backend"
echo -e "${GREEN}✓ Backend イメージビルド完了${NC}"

echo "Frontend イメージをビルド中..."
docker build -t study-ckad-frontend:latest "$PROJECT_ROOT/frontend"
echo -e "${GREEN}✓ Frontend イメージビルド完了${NC}\n"

# ------------------------------------------
# 5. Helmfileによる全コンポーネントのデプロイ
# ------------------------------------------
echo -e "${YELLOW}[5/6] Helmfileによるデプロイ...${NC}"

cd "$PROJECT_ROOT/k8s/helmfile"

echo "Helmfile sync を実行中（数分かかります）..."
helmfile sync

echo -e "${GREEN}✓ 全コンポーネントのデプロイが完了しました${NC}\n"

# ------------------------------------------
# 6. ArgoCD Application の適用
# ------------------------------------------
echo -e "${YELLOW}[6/6] ArgoCD Applicationの適用...${NC}"

# ArgoCDの準備を待機
echo "ArgoCDの起動を待機中..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s 2>/dev/null || true

# ArgoCD Application CRDの適用
kubectl apply -f "$PROJECT_ROOT/k8s/argocd/" 2>/dev/null || echo "ArgoCD Applicationの適用をスキップ（CRDが未Ready の可能性）"

echo -e "${GREEN}✓ ArgoCD Applicationを適用しました${NC}\n"

# ------------------------------------------
# セットアップ完了 - アクセス情報の表示
# ------------------------------------------
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ セットアップ完了！                       ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")

echo -e "${GREEN}=== アクセス情報 ===${NC}"
echo ""

# ArgoCD パスワード取得
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "取得失敗（後で再取得してください）")
echo -e "📦 ${YELLOW}ArgoCD UI:${NC}"
echo "   URL:      https://localhost:8080 (port-forward後)"
echo "   ユーザー: admin"
echo "   パスワード: ${ARGOCD_PASS}"
echo "   起動コマンド: kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo ""

echo -e "📊 ${YELLOW}Grafana UI:${NC}"
echo "   URL:      http://localhost:3000 (port-forward後)"
echo "   ユーザー: admin"
echo "   パスワード: admin"
echo "   起動コマンド: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 &"
echo ""

echo -e "🌐 ${YELLOW}アプリケーション:${NC}"
echo "   Minikube IP: ${MINIKUBE_IP}"
echo "   Frontend:    http://${MINIKUBE_IP}/"
echo "   Backend API: http://${MINIKUBE_IP}/api/v1/tasks"
echo ""

echo -e "💡 ${YELLOW}便利なコマンド:${NC}"
echo "   kubectl get pods -A          # 全Podの確認"
echo "   kubectl get svc -A           # 全Serviceの確認"
echo "   minikube dashboard           # Minikubeダッシュボード"
echo "   helmfile -f k8s/helmfile/helmfile.yaml status  # リリース状況確認"
echo ""
echo -e "${GREEN}Happy Learning! 🎉${NC}"
