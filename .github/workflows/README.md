# GitHub Packages Publishing Workflows

This directory contains workflows for publishing Playwright packages to GitHub Packages and GitHub Container Registry.

## Available Workflows

### publish_release.yml
Publishes npm packages to GitHub Packages registry.

**Triggers:**
- Manual trigger via `workflow_dispatch`
- Scheduled runs (daily at 5:10 AM UTC)
- Pushes to `release-*` branches
- Release publication events

**Published Packages:**
- `@next` versions: Published from `main` branch
- `@beta` versions: Published from `release-*` branches
- `@latest` versions: Published when a GitHub release is created

### publish_release_docker.yml
Publishes Docker images to GitHub Container Registry (ghcr.io).

**Triggers:**
- Manual trigger via `workflow_dispatch`
- Release publication events

## Consuming Packages in Another Workflow

### NPM Packages from GitHub Packages

To consume the published npm packages in another workflow:

```yaml
steps:
  - name: Setup Node.js
    uses: actions/setup-node@v6
    with:
      node-version: 20
      registry-url: 'https://npm.pkg.github.com'
      scope: '@iceteagroup-testmanager'
  
  - name: Configure npm authentication
    run: |
      echo "//npm.pkg.github.com/:_authToken=${{ secrets.GITHUB_TOKEN }}" > ~/.npmrc
      echo "@iceteagroup-testmanager:registry=https://npm.pkg.github.com" >> ~/.npmrc
  
  - name: Install Playwright package
    run: npm install @iceteagroup-testmanager/playwright
    env:
      NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Docker Images from GitHub Container Registry

To use the published Docker images in another workflow:

```yaml
steps:
  - name: Login to GitHub Container Registry
    uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
  
  - name: Pull Playwright Docker image
    run: docker pull ghcr.io/iceteagroup-testmanager/playwright:latest
  
  - name: Run tests in Docker
    run: docker run ghcr.io/iceteagroup-testmanager/playwright:latest npx playwright test
```

## Package Permissions

GitHub Packages requires authentication to install packages, even for public packages. Ensure your workflow has the necessary permissions:

```yaml
permissions:
  contents: read
  packages: read  # Required to pull packages
```

## Notes

- All test-related workflows have been removed
- Infrastructure and maintenance workflows have been removed
- Only publishing workflows remain
- Packages are published to the repository owner's namespace
- Docker images are published to `ghcr.io/<owner>/<image>:<tag>`
