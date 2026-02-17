# ==============================================
# CKAD学習用プロジェクト セットアップスクリプト
# 対象OS: Windows (PowerShell 5.1+)
# ==============================================
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# カラー関数
function Write-Step { param($msg) Write-Host "`n$msg" -ForegroundColor Yellow }
function Write-OK { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "  $msg" -ForegroundColor Cyan }

# ロゴ表示
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  🎓 CKAD Study Project - Setup Script       ║" -ForegroundColor Blue
Write-Host "║  Kubernetes Full-Stack Learning Environment  ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# ------------------------------------------
# 1. 必須ツールのチェック
# ------------------------------------------
Write-Step "[1/6] 必須ツールの確認..."

$missing = $false

function Test-Tool {
    param(
        [string]$Name,
        [string]$InstallHint
    )
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        Write-Fail "${Name} が見つかりません"
        Write-Info "インストール方法: $InstallHint"
        return $false
    } else {
        Write-OK "${Name} が見つかりました ($($cmd.Source))"
        return $true
    }
}

if (-not (Test-Tool "docker" "https://www.docker.com/products/docker-desktop/")) { $missing = $true }
if (-not (Test-Tool "minikube" "choco install minikube")) { $missing = $true }
if (-not (Test-Tool "kubectl" "choco install kubernetes-cli")) { $missing = $true }
if (-not (Test-Tool "helm" "choco install kubernetes-helm")) { $missing = $true }
if (-not (Test-Tool "helmfile" "choco install helmfile")) { $missing = $true }

if ($missing) {
    Write-Host ""
    Write-Fail "必須ツールが不足しています。上記のインストール方法を参考にインストールしてください。"
    exit 1
}

Write-Host ""
Write-OK "全ての必須ツールが利用可能です！"

# ------------------------------------------
# 2. Helm Diff プラグインのインストール
# ------------------------------------------
Write-Step "[2/6] Helm Diff プラグインの確認..."

$helmPlugins = helm plugin list 2>$null
if ($helmPlugins -notmatch "diff") {
    Write-Host "helm-diff プラグインをインストール中..."
    helm plugin install https://github.com/databus23/helm-diff
    Write-OK "helm-diff プラグインをインストールしました"
} else {
    Write-OK "helm-diff プラグインは既にインストール済みです"
}

# ------------------------------------------
# 3. Minikubeの起動
# ------------------------------------------
Write-Step "[3/6] Minikubeクラスタの起動..."

$minikubeStatus = minikube status -f '{{.Host}}' 2>$null
if ($minikubeStatus -eq "Running") {
    Write-OK "Minikubeは既に起動しています"
} else {
    Write-Host "Minikubeを起動します（CPUs: 4, Memory: 8GB）..."
    minikube start --cpus=4 --memory=8192 --driver=docker
    Write-OK "Minikubeが起動しました"
}

# Addon有効化
Write-Host "Minikube Addonを有効化中..."
minikube addons enable ingress 2>$null
minikube addons enable metrics-server 2>$null
Write-OK "Addon（ingress, metrics-server）が有効化されました"

# ------------------------------------------
# 4. コンテナイメージのビルド
# ------------------------------------------
Write-Step "[4/6] コンテナイメージのビルド..."

# MinikubeのDocker環境を使用
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "Backend イメージをビルド中..."
docker build -t study-ckad-backend:latest "$ProjectRoot\backend"
Write-OK "Backend イメージビルド完了"

Write-Host "Frontend イメージをビルド中..."
docker build -t study-ckad-frontend:latest "$ProjectRoot\frontend"
Write-OK "Frontend イメージビルド完了"

# ------------------------------------------
# 5. Helmfileによる全コンポーネントのデプロイ
# ------------------------------------------
Write-Step "[5/6] Helmfileによるデプロイ..."

Push-Location "$ProjectRoot\k8s\helmfile"

Write-Host "Helmfile sync を実行中（数分かかります）..."
helmfile sync

Pop-Location

Write-OK "全コンポーネントのデプロイが完了しました"

# ------------------------------------------
# 6. ArgoCD Application の適用
# ------------------------------------------
Write-Step "[6/6] ArgoCD Applicationの適用..."

Write-Host "ArgoCDの起動を待機中..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s 2>$null

kubectl apply -f "$ProjectRoot\k8s\argocd\" 2>$null

Write-OK "ArgoCD Applicationを適用しました"

# ------------------------------------------
# セットアップ完了 - アクセス情報の表示
# ------------------------------------------
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  ✅ セットアップ完了！                       ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

$MinikubeIP = minikube ip 2>$null

# ArgoCD パスワード取得
try {
    $ArgoCDPass = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
    $ArgoCDPass = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ArgoCDPass))
} catch {
    $ArgoCDPass = "取得失敗（後で再取得してください）"
}

Write-Host "=== アクセス情報 ===" -ForegroundColor Green
Write-Host ""

Write-Host "📦 ArgoCD UI:" -ForegroundColor Yellow
Write-Host "   URL:      https://localhost:8080 (port-forward後)"
Write-Host "   ユーザー: admin"
Write-Host "   パスワード: $ArgoCDPass"
Write-Host "   起動コマンド: kubectl port-forward svc/argocd-server -n argocd 8080:443"
Write-Host ""

Write-Host "📊 Grafana UI:" -ForegroundColor Yellow
Write-Host "   URL:      http://localhost:3000 (port-forward後)"
Write-Host "   ユーザー: admin"
Write-Host "   パスワード: admin"
Write-Host "   起動コマンド: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
Write-Host ""

Write-Host "🌐 アプリケーション:" -ForegroundColor Yellow
Write-Host "   Minikube IP: $MinikubeIP"
Write-Host "   Frontend:    http://${MinikubeIP}/"
Write-Host "   Backend API: http://${MinikubeIP}/api/v1/tasks"
Write-Host ""

Write-Host "💡 便利なコマンド:" -ForegroundColor Yellow
Write-Host "   kubectl get pods -A          # 全Podの確認"
Write-Host "   kubectl get svc -A           # 全Serviceの確認"
Write-Host "   minikube dashboard           # Minikubeダッシュボード"
Write-Host "   helmfile -f k8s\helmfile\helmfile.yaml status  # リリース状況確認"
Write-Host ""
Write-Host "Happy Learning! 🎉" -ForegroundColor Green
