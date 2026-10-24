---
name: deploy-html-pages
description: >-
  Use this skill whenever the user wants to create, scaffold, or deploy an HTML web application
  to GitHub Pages and obtain an active, live URL. Works seamlessly on Windows without requiring
  Git or GitHub CLI installed locally by leveraging GitHub REST API via PowerShell.
---

# Deploy HTML Pages Skill

This skill teaches the agent how to build beautiful, modern HTML web applications and deploy them directly to **GitHub Pages** to get an immediate, publicly accessible live URL (`https://<username>.github.io/<repo-name>/`).

---

## Capabilities & Architecture

- **Zero Local Git Requirement**: Deploys via PowerShell using GitHub REST API v3 (`Invoke-RestMethod`).
- **Supports Both Formats**:
  - Single-file standalone apps (`index.html` with embedded styles & scripts).
  - Multi-file projects (HTML, CSS, JS, and image assets).
- **Automated Workflow**:
  1. Authenticates using GitHub Personal Access Token (PAT).
  2. Creates public repository automatically if not present.
  3. Uploads or updates files on the `main` branch with base64 encoding and sha tracking.
  4. Enables GitHub Pages automatically with `main` branch root.
  5. Outputs the public live URL and repository links.

---

## Workflow Steps

### Step 1: Craft the Web Application

When creating the web application, adhere to high-aesthetic standards:
1. **Typography & Styling**: Use Google Fonts (e.g. Outfit, Plus Jakarta Sans, Inter), CSS variables, sleek dark/light modes, and glassmorphic card styling.
2. **Interactivity**: Include responsive layout, interactive micro-animations, and clean JavaScript logic.
3. **Reference Template**: If generating a single-file application, inspect [template-single.html](./resources/template-single.html) for design tokens and structure.

### Step 2: Verify Authentication Token

The deployment script requires a GitHub Personal Access Token (PAT) with `repo` scope:
1. Check if `$env:GITHUB_TOKEN` is set, or if a `.env` file exists with `GITHUB_TOKEN=ghp_...`.
2. If no token is configured, instruct the user to generate one using the quick guide:
   - Guide: [GitHub Token Guide](./references/github_token_guide.md)
   - Quick Link: [https://github.com/settings/tokens/new?scopes=repo](https://github.com/settings/tokens/new?scopes=repo)
   - Offer to create a `.env` file using [env.example](./resources/env.example).

### Step 3: Run the Deploy Script

Execute the bundled deployment script from the workspace or skill directory:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\26007239\.gemini\config\skills\deploy-html-pages\scripts\deploy.ps1" -TargetPath ".\index.html" -RepoName "my-web-app"
```

#### Script Parameters:
| Parameter | Description | Default |
| :--- | :--- | :--- |
| `-TargetPath` | Path to `index.html` or a folder containing web files | `index.html` or current directory |
| `-RepoName` | Repository name on GitHub | Current folder name |
| `-RepoDescription` | Description for GitHub repository | "Web application created and deployed with Antigravity" |
| `-Token` | Explicit token (optional) | Reads from `$env:GITHUB_TOKEN` or `.env` |

### Step 4: Verification & Live Link Delivery

1. The script will output the live URL: `https://<username>.github.io/<repo-name>/`.
2. Present the live URL and GitHub repository link clearly to the user.
3. Remind the user: On initial repository creation, GitHub Pages may take 30–90 seconds to complete its first build.
