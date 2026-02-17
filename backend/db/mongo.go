package db

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var Client *mongo.Client

// Connect はMongoDBへの接続を確立する
func Connect() error {
	uri := os.Getenv("MONGODB_URI")
	if uri == "" {
		uri = "mongodb://localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOptions := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return fmt.Errorf("MongoDB接続エラー: %w", err)
	}

	// 接続確認
	err = client.Ping(ctx, nil)
	if err != nil {
		return fmt.Errorf("MongoDB Pingエラー: %w", err)
	}

	Client = client
	log.Println("MongoDBに接続しました")
	return nil
}

// Disconnect はMongoDBとの接続を切断する
func Disconnect() {
	if Client != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := Client.Disconnect(ctx); err != nil {
			log.Printf("MongoDB切断エラー: %v", err)
		}
		log.Println("MongoDB接続を切断しました")
	}
}

// GetCollection は指定されたコレクションを返す
func GetCollection(collectionName string) *mongo.Collection {
	dbName := os.Getenv("MONGODB_DATABASE")
	if dbName == "" {
		dbName = "taskdb"
	}
	return Client.Database(dbName).Collection(collectionName)
}
