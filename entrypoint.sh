#!/bin/bash
set -e

echo "GitHub Runner Entrypoint Starting..."

ls -la /home/githubrunner

# Validate required environment variables
if [[ -z "$GITHUB_RUNNER_URL" ]]; then
    echo "Error: GITHUB_RUNNER_URL is not set"
    exit 1
fi

if [[ -z "$GITHUB_PAT" ]]; then
    echo "Error: GITHUB_PAT is not set"
    exit 1
fi


# Determine if the URL is for an organization or a repository
if [[ "$GITHUB_RUNNER_URL" == *"github.com"* ]]; then
    # This logic assumes a simple "github.com/org" format for orgs and "github.com/org/repo" for repos.
    # We count the slashes after "github.com/". Two slashes means a repo, one slash means an org.
    URL_PATH=$(echo "$GITHUB_RUNNER_URL" | sed 's|https://github.com/||' | tr -s '/')
    NUM_SLASHES=$(echo "$URL_PATH" | tr -cd '/' | wc -c)

    if [ "$NUM_SLASHES" -ge 1 ]; then
        # This is likely a repository URL
        API_URL="repos"
        REPO_OR_ORG=$(echo "$URL_PATH" | cut -d '/' -f 1-2)
    else
        # This is an organization URL
        API_URL="orgs"
        REPO_OR_ORG=$(echo "$URL_PATH" | cut -d '/' -f 1)
    fi

    API_ENDPOINT="https://api.github.com/$API_URL/$REPO_OR_ORG/actions/runners/registration-token"
else
    # Fallback or other URL types, assuming it's already an API endpoint
    API_ENDPOINT="$GITHUB_RUNNER_URL"
fi

echo "Fetching a new registration token from $API_ENDPOINT..."

# Get the runner registration token from the GitHub API using the PAT
# Use --fail to exit on HTTP errors
TOKEN=$(curl -sS --fail -X POST \
    -H "Authorization: token $GITHUB_PAT" \
    -H "Accept: application/vnd.github+json" \
    "$API_ENDPOINT" | jq -r .token)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to retrieve a registration token. Check your GITHUB_PAT and GITHUB_RUNNER_URL."
    exit 1
fi

echo "Successfully retrieved registration token."



# Set defaults if not provided
GITHUB_RUNNER_NAME=${GITHUB_RUNNER_NAME:-$(hostname)}
GITHUB_RUNNER_LABELS=${GITHUB_RUNNER_LABELS:-"self-hosted"}

echo "Runner Name: $GITHUB_RUNNER_NAME"
echo "Runner Labels: $GITHUB_RUNNER_LABELS"
echo "Repository URL: $GITHUB_RUNNER_URL"

# Configure the runner if not already configured
if [ ! -f ".runner" ]; then
    echo "Configuring runner for the first time..."
    /home/githubrunner/config.sh \
        --url "$GITHUB_RUNNER_URL" \
        --token "$TOKEN" \
        --name "$GITHUB_RUNNER_NAME" \
        --labels "$GITHUB_RUNNER_LABELS" \
        --work "_work" \
        --unattended \
        --replace
    echo "Runner configured successfully"
else
    echo "Runner already configured, using existing configuration"
fi

# Graceful shutdown handler
cleanup() {
    echo "Removing runner..."
    /home/githubrunner/config.sh remove --unattended --token "$GITHUB_RUNNER_TOKEN" || true
}
trap 'cleanup' SIGTERM SIGINT

echo "Starting GitHub Actions runner..."
/home/githubrunner/run.sh &

# Wait for the background process
wait $!
