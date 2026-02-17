package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/rs/cors"

	"github.com/study-ckad/backend/db"
	"github.com/study-ckad/backend/handler"
)

func main() {
	// MongoDB接続
	if err := db.Connect(); err != nil {
		log.Fatalf("MongoDB接続に失敗: %v", err)
	}
	defer db.Disconnect()

	// ルーター設定
	r := mux.NewRouter()

	// ヘルスチェックエンドポイント（Liveness/Readiness Probe用）
	r.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	}).Methods("GET")

	r.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		// DB接続を確認
		if db.Client != nil {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte(`{"status": "ready"}`))
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte(`{"status": "not ready"}`))
		}
	}).Methods("GET")

	// Prometheus メトリクスエンドポイント
	r.Handle("/metrics", promhttp.Handler())

	// API ルート
	api := r.PathPrefix("/api/v1").Subrouter()
	api.HandleFunc("/tasks", handler.GetTasks).Methods("GET")
	api.HandleFunc("/tasks/{id}", handler.GetTask).Methods("GET")
	api.HandleFunc("/tasks", handler.CreateTask).Methods("POST")
	api.HandleFunc("/tasks/{id}", handler.UpdateTask).Methods("PUT")
	api.HandleFunc("/tasks/{id}", handler.DeleteTask).Methods("DELETE")

	// CORS設定
	corsHandler := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	})

	// サーバー起動
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("サーバーを起動します: port=%s", port)
	if err := http.ListenAndServe(":"+port, corsHandler.Handler(r)); err != nil {
		log.Fatalf("サーバー起動エラー: %v", err)
	}
}
