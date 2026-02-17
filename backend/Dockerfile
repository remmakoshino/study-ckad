# ============================================
# マルチステージビルド: Go Backend
# CKAD学習ポイント: コンテナイメージの最適化
# ============================================

# --- Stage 1: ビルドステージ ---
FROM golang:1.22-alpine AS builder

# セキュリティ: 非rootユーザーとして実行するための準備
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# 依存関係を先にコピー（Dockerキャッシュ活用）
COPY go.mod ./
RUN go mod download

# ソースコードをコピーしてビルド
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags="-w -s" -o /app/server .

# --- Stage 2: 実行ステージ ---
FROM alpine:3.19

# セキュリティ: CA証明書とタイムゾーンデータ
RUN apk --no-cache add ca-certificates tzdata

# セキュリティ: 非rootユーザーの作成
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# ビルドステージからバイナリをコピー
COPY --from=builder /app/server .

# 非rootユーザーに切り替え
USER appuser

# ポート公開
EXPOSE 8080

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# エントリーポイント
ENTRYPOINT ["./server"]
