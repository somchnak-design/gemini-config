# Guide: How to Generate a GitHub Personal Access Token (PAT)

To deploy HTML web applications to GitHub Pages without installing Git on your system, the `deploy-html-pages` skill uses GitHub's REST API. This requires a **Personal Access Token (Classic)** with the `repo` permission scope.

---

## Quick Generation Steps

1. **Open GitHub Token Settings**:
   Navigate directly to: [https://github.com/settings/tokens/new?scopes=repo](https://github.com/settings/tokens/new?scopes=repo)
   *(Or go to GitHub.com → Profile Icon → Settings → Developer Settings → Personal access tokens → Tokens (classic) → Generate new token (classic))*.

2. **Configure Token**:
   - **Note**: Enter a description such as `Antigravity Deployer`.
   - **Expiration**: Select your preferred lifespan (e.g., `30 days`, `90 days`, or `No expiration`).
   - **Select scopes**: Check the **`repo`** checkbox (this grants full control of private and public repositories, which is needed to create repositories and enable GitHub Pages).

3. **Generate and Copy**:
   - Scroll to the bottom and click **Generate token**.
   - Copy the generated token string (starts with `ghp_...`).
   *(GitHub only displays this string once!)*

---

## How to Provide the Token to the Skill

You can supply the token in any of the following three ways:

### Option A: Local `.env` File (Recommended per project)
Create a `.env` file in your workspace directory:
```env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Option B: PowerShell Environment Variable (Session-wide)
Run in PowerShell:
```powershell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Option C: Pass Directly to Script
```powershell
.\deploy.ps1 -TargetPath .\index.html -Token "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```
