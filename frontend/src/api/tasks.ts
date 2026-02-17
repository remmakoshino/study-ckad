const API_BASE = '/api/v1';

export interface Task {
  id: string;
  title: string;
  description: string;
  status: 'pending' | 'in_progress' | 'completed';
  created_at: string;
  updated_at: string;
}

export interface CreateTaskInput {
  title: string;
  description: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  status?: string;
}

export async function getTasks(): Promise<Task[]> {
  const res = await fetch(`${API_BASE}/tasks`);
  if (!res.ok) throw new Error('Failed to fetch tasks');
  return res.json();
}

export async function getTask(id: string): Promise<Task> {
  const res = await fetch(`${API_BASE}/tasks/${id}`);
  if (!res.ok) throw new Error('Failed to fetch task');
  return res.json();
}

export async function createTask(input: CreateTaskInput): Promise<Task> {
  const res = await fetch(`${API_BASE}/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error('Failed to create task');
  return res.json();
}

export async function updateTask(id: string, input: UpdateTaskInput): Promise<Task> {
  const res = await fetch(`${API_BASE}/tasks/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error('Failed to update task');
  return res.json();
}

export async function deleteTask(id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/tasks/${id}`, {
    method: 'DELETE',
  });
  if (!res.ok) throw new Error('Failed to delete task');
}
