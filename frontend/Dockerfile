# ============================================
# マルチステージビルド: React Frontend
# CKAD学習ポイント: Nginxによる静的ファイル配信
# ============================================

# --- Stage 1: ビルドステージ ---
FROM node:20-alpine AS builder

WORKDIR /app

# 依存関係を先にインストール（キャッシュ活用）
COPY package.json ./
RUN npm install

# ソースをコピーしてビルド
COPY . .
RUN npm run build

# --- Stage 2: 実行ステージ ---
FROM nginx:1.25-alpine

# カスタムNginx設定をコピー
COPY nginx.conf /etc/nginx/conf.d/default.conf

# ビルド成果物をNginxの公開ディレクトリにコピー
COPY --from=builder /app/dist /usr/share/nginx/html

# 非rootユーザーとして実行する設定
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
