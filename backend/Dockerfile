FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app/backend

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app ./app
COPY backend/alembic.ini .
COPY backend/alembic ./alembic
COPY SafeMyanmar_Yangon_2026-08-17 /app/SafeMyanmar_Yangon_2026-08-17

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
