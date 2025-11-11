#!/usr/bin/env bash
set -e
set -x

function cleanup {
  # Cleanup all possibly created package tars.
  if [[ ! -z "${PLAYWRIGHT_TGZ}" ]]; then rm -rf "${PLAYWRIGHT_TGZ}"; fi
  if [[ ! -z "${PLAYWRIGHT_CORE_TGZ}" ]]; then rm -rf "${PLAYWRIGHT_CORE_TGZ}"; fi
  if [[ ! -z "${PLAYWRIGHT_WEBKIT_TGZ}" ]]; then rm -rf "${PLAYWRIGHT_WEBKIT_TGZ}"; fi
  if [[ ! -z "${PLAYWRIGHT_FIREFOX_TGZ}" ]]; then rm -rf "${PLAYWRIGHT_FIREFOX_TGZ}"; fi
  if [[ ! -z "${PLAYWRIGHT_CHROMIUM_TGZ}" ]]; then rm -rf "${PLAYWRIGHT_CHROMIUM_TGZ}"; fi
  
  # Restore package.json backups if they exist
  if [[ -d "$(dirname $0)/../packages" ]]; then
    find "$(dirname $0)/../packages" -name "package.json.backup" 2>/dev/null | while read backup; do
      original="${backup%.backup}"
      if [[ -f "${backup}" ]]; then
        mv "${backup}" "${original}"
        echo "Restored ${original} from backup"
      fi
    done
  fi
}

trap "cleanup; cd $(pwd -P)" EXIT
cd "$(dirname $0)"

if [[ $1 == "--help" ]]; then
  echo "usage: $(basename $0) [--release|--alpha|--beta]"
  echo
  echo "Publishes all packages."
  echo
  echo "--release                publish @latest version of all packages"
  echo "--alpha                  publish @next version of all packages"
  echo "--beta                   publish @beta version of all packages"
  exit 1
fi

if [[ $# < 1 ]]; then
  echo "Please specify either --release, --beta or --alpha"
  exit 1
fi

if ! command -v npm >/dev/null; then
  echo "ERROR: NPM is not found"
  exit 1
fi

cd ..

NPM_PUBLISH_TAG="next"

VERSION=$(node -e 'console.log(require("./package.json").version)')

if [[ "$1" == "--release" ]]; then
  if [[ -n $(git status -s) ]]; then
    echo "ERROR: git status is dirty; some uncommitted changes or untracked files"
    exit 1
  fi
  # Ensure package version does not contain dash.
  if [[ "${VERSION}" == *-* ]]; then
    echo "ERROR: cannot publish pre-release version ${VERSION} with --release flag"
    exit 1
  fi
  NPM_PUBLISH_TAG="latest"
elif [[ "$1" == "--alpha" ]]; then
  # Ensure package version contains alpha.
  if [[ "${VERSION}" != *-alpha* ]]; then
    echo "ERROR: cannot publish release version ${VERSION} with --alpha flag"
    exit 1
  fi

  NPM_PUBLISH_TAG="next"
elif [[ "$1" == "--beta" ]]; then
  # Ensure package version contains beta.
  if [[ "${VERSION}" != *-beta* ]]; then
    echo "ERROR: cannot publish release version ${VERSION} with --beta flag"
    exit 1
  fi

  NPM_PUBLISH_TAG="beta"
else
  echo "unknown argument - '$1'"
  exit 1
fi

echo "==================== Publishing version ${VERSION} ================"
node ./utils/workspace.js --ensure-consistent

# Use NPM_REGISTRY if set, otherwise default to npmjs.org
REGISTRY="${NPM_REGISTRY:-https://registry.npmjs.org}"
echo "Publishing to registry: ${REGISTRY}"

# If publishing to GitHub Packages, ensure authentication is configured
if [[ "${REGISTRY}" == *"npm.pkg.github.com"* ]]; then
  if [[ -z "${NODE_AUTH_TOKEN}" ]]; then
    echo "ERROR: NODE_AUTH_TOKEN is required for publishing to GitHub Packages"
    exit 1
  fi
  echo "Configuring authentication for GitHub Packages..."
  echo "//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}" > .npmrc
  echo "registry=${REGISTRY}" >> .npmrc
  
  # Extract organization name from git remote URL
  GIT_REMOTE=$(git remote get-url origin)
  ORG_NAME=$(echo "${GIT_REMOTE}" | sed -E 's|.*github.com[:/]([^/]+)/.*|\1|')
  echo "Organization name: ${ORG_NAME}"
  
  # For GitHub Packages, we need to scope unscoped packages with the organization name
  # Create temporary backup and modify package.json files
  node ./utils/workspace.js --list-public-package-paths | while read package; do
    PACKAGE_JSON="${package}/package.json"
    PACKAGE_NAME=$(node -e "console.log(require('${PACKAGE_JSON}').name)")
    
    # Only modify if the package name is not already scoped
    if [[ "${PACKAGE_NAME}" != @* ]]; then
      echo "Scoping package ${PACKAGE_NAME} -> @${ORG_NAME}/${PACKAGE_NAME}"
      # Backup original package.json
      cp "${PACKAGE_JSON}" "${PACKAGE_JSON}.backup"
      # Update package name to be scoped
      node -e "
        const fs = require('fs');
        const pkg = require('${PACKAGE_JSON}');
        pkg.name = '@${ORG_NAME}/' + pkg.name;
        fs.writeFileSync('${PACKAGE_JSON}', JSON.stringify(pkg, null, 2) + '\n');
      "
    fi
  done
fi

node ./utils/workspace.js --list-public-package-paths | while read package
do
  npm publish --access=public ${package} --tag="${NPM_PUBLISH_TAG}"
done

# Clean up .npmrc and restore package.json files if they were modified for GitHub Packages
if [[ "${REGISTRY}" == *"npm.pkg.github.com"* ]]; then
  rm -f .npmrc
  
  # Restore original package.json files from backups
  node ./utils/workspace.js --list-public-package-paths | while read package; do
    PACKAGE_JSON="${package}/package.json"
    if [[ -f "${PACKAGE_JSON}.backup" ]]; then
      mv "${PACKAGE_JSON}.backup" "${PACKAGE_JSON}"
      echo "Restored ${PACKAGE_JSON}"
    fi
  done
fi

echo "Done."
