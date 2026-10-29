# ==========================================
# Tahap 1: Build Frontend Assets (Vite & Tailwind)
# ==========================================
FROM node:20-alpine AS frontend-builder
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ==========================================
# Tahap 2: Runtime PHP 8.4 (FrankenPHP)
# ==========================================
FROM dunglas/frankenphp:1-php8.4-alpine

# Install ekstensi PHP yang dibutuhkan Laravel & library Excel/PDF
RUN install-php-extensions \
    pdo_mysql \
    gd \
    zip \
    bcmath \
    exif \
    pcntl \
    intl \
    opcache

# Set direktori kerja
WORKDIR /app

# Copy Composer dari image resmi
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy source code aplikasi
COPY . /app

# Copy hasil build frontend dari tahap 1
COPY --from=frontend-builder /app/public/build /app/public/build

# Install dependencies PHP (optimasi untuk production)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Berikan izin akses folder storage dan cache
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# Expose port HTTP
EXPOSE 80

# Environment FrankenPHP untuk Laravel (otomatis membaca /app/public)
ENV SERVER_NAME=":80"
ENV CADDY_GLOBAL_OPTIONS="auto_https off"
