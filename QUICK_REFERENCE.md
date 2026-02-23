# Quick Reference: MaxLab GitHub Actions Deployment

## 🐳 Docker Hub Image Variables

Use these in `.env` for local image build/push:

```env
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-access-token
DOCKER_REPOSITORY=maxlab
DOCKER_TAG=dev
```

- `./scripts/docker-build.ps1` builds `latest` and `DOCKER_TAG`.
- `./scripts/docker-push.ps1` pushes both tags to Docker Hub.
- `./scripts/docker-run.ps1` uses `docker compose up --build`.

## 🚀 Deploy in 3 Steps

### Step 1: Go to Actions
```
https://github.com/YOUR-USERNAME/MaxLab/actions
```

### Step 2: Select Workflow
Find and click: **Deploy MaxLab**

### Step 3: Run
Click: **Run workflow** → Confirm

---

## 📊 What Happens Next

1. **Validation (Ubuntu)** - Parallel checks
   - ✓ PowerShell scripts
   - ✓ Python code
   - ✓ Notebook outputs

2. **Deployment (Windows)** - If all pass
   - ✓ Clone/pull code to `D:\apps\MaxLab`
   - ✓ Verify critical files
   - ✓ Show deployment summary

3. **Done!**
   - ✓ Code deployed
   - ✓ Ready to run setup.ps1/start.ps1

---

## 🎯 Options

### Custom Branch (Optional)
Instead of `main`, deploy a different branch:
1. Click "Run workflow"
2. Enter branch name in the input field
3. Click "Run workflow"

### Check Status
- **Green ✓** = Success
- **Red ✗** = Failed (check logs)
- **Yellow ⟳** = In progress

---

## 🐛 If Something Fails

### Validation Failed
- Check GitHub Actions logs
- Read the specific error
- Fix code locally
- Push to GitHub
- Try again

### Deployment Failed
- Verify Windows server is online
- Check runner is configured
- Verify `D:\apps\MaxLab` permissions
- Check internet connectivity

---

## 📝 Files Created

| File | Purpose |
|------|---------|
| `.github/workflows/deploy.yml` | Main workflow |
| `DEPLOYMENT_GUIDE.md` | Full documentation |
| `QUICK_REFERENCE.md` | This file |

---

## ✅ Pre-Deployment Checklist

Before first deployment:
- [ ] Windows server has GitHub Actions runner
- [ ] Runner is online and has `windows-server` label
- [ ] Git is installed on Windows server
- [ ] `D:\apps\MaxLab` directory is accessible
- [ ] Repository is pushed to GitHub

---

## 💡 Pro Tips

1. **Branch Specific Testing**
   - Deploy feature branches to test before merge

2. **Deployment History**
   - GitHub Actions tab shows all deployments
   - Click any run to see details

3. **Check After Deploy**
   ```powershell
   cd D:\apps\MaxLab
   ./setup.ps1  # First time only
   ./start.ps1  # Launch JupyterLab
   ```

4. **Rollback If Needed**
   ```powershell
   cd D:\apps\MaxLab
   git log --oneline -n 5
   git checkout <commit-hash>
   ```

---

## 🔗 Useful Links

- Actions Tab: `Actions` menu in GitHub repo
- Workflow File: `.github/workflows/deploy.yml`
- Full Guide: `DEPLOYMENT_GUIDE.md`
- Implementation Plan: Session plan.md

---

## ❓ FAQ

**Q: Can I deploy from a different branch?**
A: Yes! Use the branch input field when running the workflow.

**Q: What if validation fails?**
A: Deployment is automatically blocked. Fix the issue and try again.

**Q: How long does deployment take?**
A: ~1-2 minutes (lint jobs + deployment).

**Q: Can I manually update the server without GitHub Actions?**
A: Yes, but GitHub Actions keeps it automated and audited.

**Q: What if the runner is offline?**
A: Workflow will wait for runner to come online or fail after timeout.

---

## 🚨 Emergency Rollback

If something goes wrong after deployment:

```powershell
# SSH to Windows server
cd D:\apps\MaxLab

# See recent versions
git log --oneline -n 10

# Go back to previous version
git checkout <previous-commit-hash>

# Restart if needed
./start.ps1
```

---

**Last Updated**: 2026-02-15
**Status**: ✅ Ready for Production
