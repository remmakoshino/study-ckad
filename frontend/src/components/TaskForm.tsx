import { useState } from 'react';
import { createTask } from '../api/tasks';

interface TaskFormProps {
  onTaskCreated: () => void;
}

function TaskForm({ onTaskCreated }: TaskFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    try {
      setSubmitting(true);
      await createTask({ title: title.trim(), description: description.trim() });
      setTitle('');
      setDescription('');
      onTaskCreated();
    } catch (err) {
      console.error('タスク作成エラー:', err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form className="task-form" onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="タスクのタイトル"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
      />
      <textarea
        placeholder="説明（任意）"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />
      <button type="submit" disabled={submitting || !title.trim()}>
        {submitting ? '作成中...' : 'タスクを追加'}
      </button>
    </form>
  );
}

export default TaskForm;
