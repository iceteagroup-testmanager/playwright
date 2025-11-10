# Playwright MCP GitHub Action

This GitHub Action sets up and runs the Playwright MCP (Model Context Protocol) server, enabling browser automation capabilities in your workflows.

## Usage

To use this action in your workflow, add the following step:

```yaml
- name: Run Playwright MCP Server
  uses: iceteagroup-testmanager/playwright@main
  with:
    browser: chrome
    headless: true
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `node-version` | Node.js version to use | No | `20` |
| `browser` | Browser to use (chrome, firefox, webkit, msedge) | No | `chrome` |
| `headless` | Run browser in headless mode | No | `false` |
| `host` | Host to bind server to | No | `localhost` |
| `port` | Port to listen on for SSE transport | No | _(empty)_ |
| `install-deps` | Install system dependencies for browsers | No | `true` |
| `additional-options` | Additional options to pass to the MCP server | No | _(empty)_ |

## Outputs

| Output | Description |
|--------|-------------|
| `server-url` | URL of the MCP server (only set if `port` is specified) |

## Examples

### Basic Usage

```yaml
name: Browser Automation

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Playwright MCP
        uses: iceteagroup-testmanager/playwright@main
        with:
          browser: chrome
          headless: true
```

### Running MCP Server on Custom Port

```yaml
- name: Start MCP Server
  id: mcp
  uses: iceteagroup-testmanager/playwright@main
  with:
    browser: firefox
    headless: true
    host: 0.0.0.0
    port: 8080
    
- name: Use MCP Server
  run: |
    echo "MCP Server is running at: ${{ steps.mcp.outputs.server-url }}"
    # Your automation tasks here
```

### Using Different Browsers

```yaml
strategy:
  matrix:
    browser: [chrome, firefox, webkit]

steps:
  - uses: actions/checkout@v4
  
  - name: Run with ${{ matrix.browser }}
    uses: iceteagroup-testmanager/playwright@main
    with:
      browser: ${{ matrix.browser }}
      headless: true
```

### With Additional Options

```yaml
- name: Run MCP with custom options
  uses: iceteagroup-testmanager/playwright@main
  with:
    browser: chrome
    headless: true
    additional-options: '--ignore-https-errors --grant-permissions geolocation'
```

## About Playwright MCP

The Playwright MCP server provides a Model Context Protocol interface for browser automation, allowing you to control browsers through a standardized API. This is particularly useful for:

- Browser automation in CI/CD pipelines
- Web scraping and data extraction
- End-to-end testing
- UI testing across different browsers
- Integration with MCP-compatible tools and services

## Requirements

- Node.js 18 or higher
- Ubuntu, macOS, or Windows runner
- Sufficient permissions to install system dependencies (if `install-deps: true`)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
