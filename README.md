# GithubRunnerContainer

A Docker container for running a self-hosted GitHub Actions runner. This project provides multiple ways to deploy and run the container.

## Prerequisites

Before using this container, you'll need:
- Docker and Docker Compose installed
- GitHub Personal Access Token (PAT) with appropriate permissions
- Your GitHub repository or organization URL

## Configuration

### Setting Up the .env File

Create a `.env` file in the project root directory with the required environment variables. This file will be automatically loaded by Docker Compose and used to configure your runner.

#### Step 1: Create the .env File

```bash
# On Windows (PowerShell or Command Prompt)
type nul > .env

# On Linux/macOS
touch .env
```

#### Step 2: Add Environment Variables

Edit the `.env` file and add the following four required variables:

```bash
GITHUB_RUNNER_URL=https://github.com/your-org-or-username
GITHUB_PAT=your-personal-access-token
GITHUB_RUNNER_NAME=your-runner-name
GITHUB_RUNNER_LABELS=your-labels
```

### Environment Variables Details

#### GITHUB_RUNNER_URL
The GitHub URL where the runner will be registered. This can be either:
- **Organization URL**: `https://github.com/your-organization` (for organization-level runners)
- **Repository URL**: `https://github.com/your-username/your-repository` (for repository-level runners)

**Example:**
```bash
GITHUB_RUNNER_URL=https://github.com/emteeoh
```

#### GITHUB_PAT
Your GitHub Personal Access Token. This token is used to authenticate with GitHub and register the runner.

**How to create a PAT:**
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "GitHub Runner Token")
4. Select the following scopes:
   - `repo` (full control of private repositories)
   - `workflow` (update GitHub Action workflows)
   - `admin:org_hook` (if using organization-level runners)
5. Click "Generate token" and copy it immediately

**Example:**
```bash
GITHUB_PAT=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890
```

**⚠️ Security Note:** Never commit the `.env` file to version control. Add it to `.gitignore`.

#### GITHUB_RUNNER_NAME
A unique name for this runner instance. This name will appear in your GitHub repository's settings under "Actions runners".

**Naming suggestions:**
- Use descriptive names reflecting the runner's purpose (e.g., `docker-builder`, `linux-tester`)
- Include the host environment if running multiple runners (e.g., `prod-runner-1`, `dev-runner-2`)
- Avoid special characters; use hyphens and underscores instead

**Example:**
```bash
GITHUB_RUNNER_NAME=my-custom-runner
```

#### GITHUB_RUNNER_LABELS
A comma-separated list of labels for the runner. These labels help you target specific runners in your GitHub Actions workflows.

**Naming suggestions:**
- `docker` - if the runner has Docker capabilities
- `linux`, `windows`, or `macos` - for OS identification
- `high-memory`, `gpu` - for special hardware
- Custom labels for your specific needs

**Example (single label):**
```bash
GITHUB_RUNNER_LABELS=docker
```

**Example (multiple labels):**
```bash
GITHUB_RUNNER_LABELS=docker,linux,production
```

### Complete .env Example

Here's a complete example of a fully configured `.env` file:

```bash
GITHUB_RUNNER_URL=https://github.com/myorganization
GITHUB_PAT=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890
GITHUB_RUNNER_NAME=docker-runner-01
GITHUB_RUNNER_LABELS=docker,linux,production
```

### Verifying Your Configuration

Before starting the container, verify your `.env` file:

```bash
# View the contents (make sure sensitive data looks correct)
cat .env

# Count the number of environment variables
cat .env | wc -l
```

## Usage

### Option 1: Using Docker Compose (Recommended)

The easiest way to get started. Docker Compose will build and manage the container for you.

```bash
# Start the container
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

**Features:**
- Automatic container management
- Service restart policy (unless-stopped)
- Environment variable handling via `.env` file
- Port mapping: `localhost:18080` → container port `8080`

### Option 2: Using Docker Compose (Legacy)

If you're using an older version of Docker, use `docker-compose` (with hyphen):

```bash
# Start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

**Note:** Modern Docker installations include `docker compose` as a plugin, so Option 1 is preferred.

### Option 3: Using Dockerfile Directly

For more control over the container configuration, build and run directly from the Dockerfile:

```bash
# Build the image
docker build -t github-runner:latest .

# Run the container
docker run -d \
  --name github-runner \
  --restart unless-stopped \
  -p 18080:8080 \
  -e GITHUB_RUNNER_URL="https://github.com/your-org-or-username" \
  -e GITHUB_PAT="your-personal-access-token" \
  -e GITHUB_RUNNER_NAME="your-runner-name" \
  -e GITHUB_RUNNER_LABELS="your-labels" \
  github-runner:latest

# View logs
docker logs -f github-runner

# Stop the container
docker stop github-runner

# Remove the container
docker rm github-runner
```

**Flags explained:**
- `-d`: Run in detached mode (background)
- `--name`: Assign a container name
- `--restart unless-stopped`: Auto-restart policy
- `-p`: Port mapping (host:container)
- `-e`: Set environment variables

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_RUNNER_URL` | GitHub repository or organization URL | Yes |
| `GITHUB_PAT` | Personal Access Token for GitHub | Yes |
| `GITHUB_RUNNER_NAME` | Name for this runner instance | Yes |
| `GITHUB_RUNNER_LABELS` | Labels for the runner (comma-separated) | No |

## Troubleshooting

### View container logs
```bash
docker logs github-runner
# or with docker compose
docker compose logs runner
```

### Check if the container is running
```bash
docker ps
```

### Remove a stopped container
```bash
docker rm github-runner
```

## Additional Information

For more details on GitHub Actions runners, visit the [GitHub Actions Runner repository](https://github.com/actions/runner).
