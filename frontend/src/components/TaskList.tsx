import { updateTask, type Task } from '../api/tasks';

interface TaskListProps {
  tasks: Task[];
  onDelete: (id: string) => void;
  onUpdate: () => void;
}

const statusLabels: Record<string, string> = {
  pending: '未着手',
  in_progress: '進行中',
  completed: '完了',
};

const nextStatus: Record<string, string> = {
  pending: 'in_progress',
  in_progress: 'completed',
  completed: 'pending',
};

function TaskList({ tasks, onDelete, onUpdate }: TaskListProps) {
  if (tasks.length === 0) {
    return <p className="empty-message">タスクがありません。新しいタスクを作成してください。</p>;
  }

  const handleStatusChange = async (task: Task) => {
    try {
      await updateTask(task.id, { status: nextStatus[task.status] });
      onUpdate();
    } catch (err) {
      console.error('ステータス更新エラー:', err);
    }
  };

  return (
    <ul className="task-list">
      {tasks.map((task) => (
        <li key={task.id} className="task-item">
          <div className="task-info">
            <div className="task-title">{task.title}</div>
            {task.description && <div className="task-desc">{task.description}</div>}
            <span className={`task-status status-${task.status}`}>
              {statusLabels[task.status] || task.status}
            </span>
          </div>
          <div className="task-actions">
            <button className="btn-status" onClick={() => handleStatusChange(task)}>
              → {statusLabels[nextStatus[task.status]]}
            </button>
            <button className="btn-delete" onClick={() => onDelete(task.id)}>
              削除
            </button>
          </div>
        </li>
      ))}
    </ul>
  );
}

export default TaskList;
