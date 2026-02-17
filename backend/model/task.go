package model

import "go.mongodb.org/mongo-driver/bson/primitive"

// Task はタスク管理アプリケーションのデータモデル
type Task struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title       string             `json:"title" bson:"title"`
	Description string             `json:"description" bson:"description"`
	Status      string             `json:"status" bson:"status"` // "pending", "in_progress", "completed"
	CreatedAt   string             `json:"created_at" bson:"created_at"`
	UpdatedAt   string             `json:"updated_at" bson:"updated_at"`
}

// CreateTaskRequest はタスク作成リクエストの構造体
type CreateTaskRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

// UpdateTaskRequest はタスク更新リクエストの構造体
type UpdateTaskRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	Status      string `json:"status"`
}
