# PowerShell helper to run the backend container locally
# Usage: Open PowerShell in project root and run `./run-local.ps1`

$image = "todo-backend:latest"

# Build image if missing
if (-not (docker images -q $image)) {
    Write-Host "Image $image not found locally. Building from ./backend..."
    docker build -t $image ./backend
}

# Run container (single-line alternative shown in README)
Write-Host "Starting container from image $image..."

docker run --rm -p 5000:5000 -e "DATABASE_URL=sqlite:///todo.db" -e "JWT_SECRET_KEY=devjwt" $image
