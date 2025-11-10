# Example: How to Use Playwright MCP Action in Other Workflows

This file shows examples of how to use the Playwright MCP GitHub Action in other workflows within your organization.

## Example 1: Basic Browser Automation

```yaml
name: Browser Automation Test

on: [push, pull_request]

jobs:
  automation:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Playwright MCP
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: chrome
          headless: true
          install-deps: true
      
      - name: Run automation scripts
        run: |
          # Your automation commands here
          echo "Playwright MCP is ready for use"
```

## Example 2: Multi-Browser Testing

```yaml
name: Cross-Browser Tests

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        browser: [chrome, firefox, webkit]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Test on ${{ matrix.browser }}
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: ${{ matrix.browser }}
          headless: true
```

## Example 3: MCP Server with Port

```yaml
name: MCP Server with API

on: [workflow_dispatch]

jobs:
  server:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Start MCP Server
        id: mcp-server
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: chrome
          headless: true
          host: 0.0.0.0
          port: 3000
      
      - name: Use MCP Server
        run: |
          echo "Server URL: ${{ steps.mcp-server.outputs.server-url }}"
          # Make requests to the MCP server
          curl ${{ steps.mcp-server.outputs.server-url }}/health || true
      
      - name: Run tests against MCP
        run: |
          # Run your tests that interact with the MCP server
          npm test
```

## Example 4: With Custom Options

```yaml
name: Advanced MCP Setup

on: [push]

jobs:
  advanced:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup MCP with custom options
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: chrome
          headless: false
          additional-options: >-
            --ignore-https-errors
            --grant-permissions geolocation,clipboard-read
            --viewport-size 1920x1080
```

## Example 5: Reusable Workflow

Create a reusable workflow in `.github/workflows/reusable-mcp.yml`:

```yaml
name: Reusable MCP Workflow

on:
  workflow_call:
    inputs:
      browser:
        required: true
        type: string
      headless:
        required: false
        type: boolean
        default: true

jobs:
  setup-mcp:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Playwright MCP
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: ${{ inputs.browser }}
          headless: ${{ inputs.headless }}
      
      - name: Run MCP-dependent tasks
        run: |
          # Your tasks here
          npm run test:e2e
```

Then call it from another workflow:

```yaml
name: Use Reusable MCP

on: [push]

jobs:
  call-mcp:
    uses: ./.github/workflows/reusable-mcp.yml
    with:
      browser: chrome
      headless: true
```

## Notes

- Replace `iceteagroup-testmanager/playwright@main` with your repository path
- You can also reference specific tags or commits instead of `@main`
- For organization-wide sharing, ensure the repository is accessible to other repos
