FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Thư viện hệ thống cần để cài mysqlclient, lxml và build CSS
RUN apt-get update && apt-get install -y --no-install-recommends \
        git gcc g++ make pkg-config \
        default-libmysqlclient-dev \
        libxml2-dev libxslt1-dev zlib1g-dev \
        gettext curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /site

# Cài thư viện Python trước để tận dụng cache khi build lại
COPY requirements.txt additional_requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r additional_requirements.txt \
    && pip install --no-cache-dir mysqlclient django-redis

# Cài công cụ build CSS theo package.json có sẵn trong repo
COPY package.json package-lock.json ./
RUN npm ci

# Chép toàn bộ mã nguồn (đã có logo, template TeCHKID của bạn)
COPY . .

# Build CSS từ SCSS; sed để sửa lỗi xuống dòng CRLF của Windows
RUN sed -i 's/\r$//' make_style.sh \
    && bash make_style.sh

# Biên dịch bản dịch tiếng Việt ngay lúc build, để không mất khi build lại.
# Mật khẩu giả chỉ dùng cho bước này; khi chạy thật vẫn lấy từ .env
RUN SECRET_KEY=build-only DB_PASSWORD=build-only python manage.py compilemessages \
    && SECRET_KEY=build-only DB_PASSWORD=build-only python manage.py compilejsi18n

EXPOSE 8000
