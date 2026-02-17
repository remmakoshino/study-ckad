import { useState, useEffect } from 'react';
import { getTasks, deleteTask, type Task } from './api/tasks';
import TaskList from './components/TaskList';
import TaskForm from './components/TaskForm';

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      const data = await getTasks();
      setTasks(data);
      setError(null);
    } catch (err) {
      setError('タスクの取得に失敗しました');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const handleDelete = async (id: string) => {
    try {
      await deleteTask(id);
      await fetchTasks();
    } catch (err) {
      setError('タスクの削除に失敗しました');
      console.error(err);
    }
  };

  const handleTaskCreated = () => {
    fetchTasks();
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>📋 CKAD Task Manager</h1>
        <p className="subtitle">Kubernetes学習用タスク管理アプリケーション</p>
      </header>
      <main className="app-main">
        <section className="form-section">
          <h2>新しいタスク</h2>
          <TaskForm onTaskCreated={handleTaskCreated} />
        </section>
        <section className="list-section">
          <h2>タスク一覧</h2>
          {loading && <p className="loading">読み込み中...</p>}
          {error && <p className="error">{error}</p>}
          {!loading && !error && (
            <TaskList tasks={tasks} onDelete={handleDelete} onUpdate={fetchTasks} />
          )}
        </section>
      </main>
    </div>
  );
}

export default App;
