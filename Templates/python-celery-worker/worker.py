from celery import Celery

app = Celery('tasks', broker='redis://localhost:6379/0')

@app.task
def process_data(item_id: int):
    return f"Processed item {item_id} in {{PROJECT_NAME}}"
