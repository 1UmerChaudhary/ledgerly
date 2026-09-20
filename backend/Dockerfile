# Cloud Run image. Migrations are NOT run here on purpose — same reasoning
# as render.yaml: they're applied directly against Neon by hand
# (`alembic upgrade head`), decoupled from app deploys, so migrations/ and
# alembic.ini are deliberately left out of the image (see .dockerignore).
FROM python:3.11-slim

# The build host's default IPv6 route to PyPI's CDN was hitting a congested
# edge (308 bytes/s observed) while IPv4 and other IPv6 edges were fast --
# prefer IPv4 for DNS resolution so pip doesn't land there. Standard glibc
# trick, doesn't disable IPv6.
RUN echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

WORKDIR /app

COPY pyproject.toml ./
COPY app ./app

RUN pip install --no-cache-dir --timeout 120 -e .

# Cloud Run sets $PORT itself (usually 8080); default matches so the image
# also runs the same way locally with `docker run`.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
