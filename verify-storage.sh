#!/bin/bash
# Verifica el storage (servicio telescope-storage, Garage) en un servidor.
# Uso, desde este directorio: ./verify-storage.sh
set -u
set -a; [ -f .env ] && . ./.env; set +a
ENVIRONMENT="${ENVIRONMENT:-dev}"
BUCKET="${S3_BUCKET:-telescope}"

echo "=== Verificación del storage (${ENVIRONMENT}) ==="
echo

echo "📦 Estado del servicio:"
docker compose ps telescope-storage 2>/dev/null
echo

echo "🏥 Health check:"
docker compose exec -T telescope-storage /garage health -q >/dev/null 2>&1 \
  && echo "✅ El storage está saludable" || echo "❌ El storage no responde"
echo

echo "🪣 Bucket ${BUCKET} (objetos y tamaño):"
docker compose exec -T telescope-storage /garage bucket info "$BUCKET" 2>/dev/null \
  | grep -E 'Size|Objects' || echo "❌ No existe el bucket ${BUCKET}"
echo

echo "🔑 Permisos de la clave de la api sobre el bucket:"
docker compose exec -T telescope-storage /garage bucket info "$BUCKET" 2>/dev/null \
  | grep -A3 -i 'keys' | tail -3
echo

echo "🔗 La api y el storage:"
if docker compose logs telescope-api 2>/dev/null | grep -q 'S3 storage initialized'; then
  echo "✅ La api llegó al storage y encontró el bucket al arrancar"
else
  echo "❌ La api no inicializó el storage. Últimos errores:"
  docker compose logs --tail=20 telescope-api 2>/dev/null | grep -i -E 'storage|bucket|s3' | tail -5
fi
echo

echo "📋 Logs recientes del storage:"
docker compose logs --no-log-prefix --tail=10 telescope-storage 2>/dev/null
