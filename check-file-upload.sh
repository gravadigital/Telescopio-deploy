#!/bin/bash
# Verifica que un archivo exista en el storage, con su tamaño y Content-Type.
# Uso, desde este directorio: ./check-file-upload.sh <key>
# La key es attachments.file_path, por ejemplo <event_id>_<participant_id>_<ts>.pdf
#
# El storage no se publica: la consulta sale de un contenedor de una sola vez en su red
# interna, firmada (SigV4) con la clave de la api.
set -u
if [ -z "${1:-}" ]; then
  echo "Uso: $0 <key>"
  echo "Ejemplo: $0 0b1c..._9f2e..._1794857180.pdf"
  exit 1
fi
set -a; [ -f .env ] && . ./.env; set +a
ENVIRONMENT="${ENVIRONMENT:-dev}"
BUCKET="${S3_BUCKET:-telescope}"

echo "=== Buscando ${BUCKET}/$1 ==="
HEADERS=$(docker run --rm --quiet --network "telescope-${ENVIRONMENT}-database" curlimages/curl:8.16.0 \
  -s -I --aws-sigv4 "aws:amz:garage:s3" --user "${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}" \
  "http://telescope-storage:3900/${BUCKET}/$1")
STATUS=$(echo "$HEADERS" | head -1 | tr -d '\r')
case "$STATUS" in
  *" 200"*)
    echo "✅ Archivo encontrado"
    echo "$HEADERS" | grep -i -E '^(content-length|content-type|last-modified|etag):' | tr -d '\r' ;;
  *" 404"*) echo "❌ No existe esa key en el bucket" ;;
  *) echo "❌ Respuesta inesperada: ${STATUS:-sin respuesta}" ;;
esac
