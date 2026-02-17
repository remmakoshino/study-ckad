package handler

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/study-ckad/backend/db"
	"github.com/study-ckad/backend/model"
)

const collectionName = "tasks"

// GetTasks は全タスクを取得する
func GetTasks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	collection := db.GetCollection(collectionName)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{})
	if err != nil {
		log.Printf("タスク取得エラー: %v", err)
		http.Error(w, `{"error": "タスクの取得に失敗しました"}`, http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	var tasks []model.Task
	if err := cursor.All(ctx, &tasks); err != nil {
		log.Printf("カーソル読み取りエラー: %v", err)
		http.Error(w, `{"error": "データの読み取りに失敗しました"}`, http.StatusInternalServerError)
		return
	}

	if tasks == nil {
		tasks = []model.Task{}
	}

	json.NewEncoder(w).Encode(tasks)
}

// GetTask は指定IDのタスクを取得する
func GetTask(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, `{"error": "無効なIDです"}`, http.StatusBadRequest)
		return
	}

	collection := db.GetCollection(collectionName)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var task model.Task
	err = collection.FindOne(ctx, bson.M{"_id": id}).Decode(&task)
	if err != nil {
		http.Error(w, `{"error": "タスクが見つかりません"}`, http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(task)
}

// CreateTask は新しいタスクを作成する
func CreateTask(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req model.CreateTaskRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error": "無効なリクエストです"}`, http.StatusBadRequest)
		return
	}

	if req.Title == "" {
		http.Error(w, `{"error": "タイトルは必須です"}`, http.StatusBadRequest)
		return
	}

	now := time.Now().Format(time.RFC3339)
	task := model.Task{
		Title:       req.Title,
		Description: req.Description,
		Status:      "pending",
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	collection := db.GetCollection(collectionName)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := collection.InsertOne(ctx, task)
	if err != nil {
		log.Printf("タスク作成エラー: %v", err)
		http.Error(w, `{"error": "タスクの作成に失敗しました"}`, http.StatusInternalServerError)
		return
	}

	task.ID = result.InsertedID.(primitive.ObjectID)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(task)
}

// UpdateTask は既存のタスクを更新する
func UpdateTask(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, `{"error": "無効なIDです"}`, http.StatusBadRequest)
		return
	}

	var req model.UpdateTaskRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error": "無効なリクエストです"}`, http.StatusBadRequest)
		return
	}

	update := bson.M{
		"$set": bson.M{
			"updated_at": time.Now().Format(time.RFC3339),
		},
	}

	if req.Title != "" {
		update["$set"].(bson.M)["title"] = req.Title
	}
	if req.Description != "" {
		update["$set"].(bson.M)["description"] = req.Description
	}
	if req.Status != "" {
		update["$set"].(bson.M)["status"] = req.Status
	}

	collection := db.GetCollection(collectionName)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	if err != nil {
		log.Printf("タスク更新エラー: %v", err)
		http.Error(w, `{"error": "タスクの更新に失敗しました"}`, http.StatusInternalServerError)
		return
	}

	if result.MatchedCount == 0 {
		http.Error(w, `{"error": "タスクが見つかりません"}`, http.StatusNotFound)
		return
	}

	var task model.Task
	collection.FindOne(ctx, bson.M{"_id": id}).Decode(&task)
	json.NewEncoder(w).Encode(task)
}

// DeleteTask はタスクを削除する
func DeleteTask(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, `{"error": "無効なIDです"}`, http.StatusBadRequest)
		return
	}

	collection := db.GetCollection(collectionName)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	result, err := collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		log.Printf("タスク削除エラー: %v", err)
		http.Error(w, `{"error": "タスクの削除に失敗しました"}`, http.StatusInternalServerError)
		return
	}

	if result.DeletedCount == 0 {
		http.Error(w, `{"error": "タスクが見つかりません"}`, http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
