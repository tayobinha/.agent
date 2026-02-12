---
name: auto-update-system
description: Secure auto-update patterns for RMM agents. GitHub release integration, cryptographic verification, rollback mechanisms, and staged deployment strategies.
allowed-tools: Read, Glob, Grep, Bash
---

# Auto-Update System

> **Mission-Critical Principle:** Updates are the #1 attack vector in enterprise software. Every decision must prioritize security over convenience.

## 🎯 What This Skill Is

This skill teaches you how to build a **secure, enterprise-grade auto-update system** for RMM agents that:

1. **Fetches updates** from GitHub Releases
2. **Verifies integrity** using cryptographic checksums
3. **Deploys safely** with rollback capability
4. **Monitors progress** across thousands of agents
5. **Prevents attacks** through defense-in-depth

**This is NOT:**
- A simple "download and replace" script
- A tutorial on GitHub API
- A one-size-fits-all solution

**This IS:**
- A security-first architecture
- Decision-making framework for updates
- Risk mitigation strategies

---

## 🔒 Security Principles (OWASP A03 + A08)

### Threat Model

| Threat | Attack Vector | Mitigation |
|--------|---------------|------------|
| **Supply Chain Attack** | Compromised GitHub account | Code signing + checksum verification |
| **Man-in-the-Middle** | Network interception | HTTPS only + certificate pinning |
| **Malicious Binary** | Tampered release | SHA256 verification before execution |
| **Privilege Escalation** | Update process exploited | Run with least privilege |
| **Denial of Service** | Mass update failure | Staged rollout + circuit breaker |

### Defense Layers

```
Layer 1: HTTPS Transport (TLS 1.3+)
Layer 2: GitHub Authentication (PAT with read-only scope)
Layer 3: Checksum Verification (SHA256)
Layer 4: Code Signing (Future: GPG/Authenticode)
Layer 5: Rollback Mechanism (Previous version backup)
Layer 6: Monitoring (Update success rate tracking)
```

---

## 📐 Architecture Decision Framework

### Question 1: Where to Host Updates?

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Backend Proxy** | Works behind firewalls, centralized control, audit trail | Requires storage | ✅ **REQUIRED for Enterprise** |
| **GitHub Releases** | Free, reliable, version control | Blocked by firewalls | ✅ Backend downloads from here |
| **Self-hosted CDN** | Full control, private | Cost, maintenance | Optional for scale |

**Decision:** Backend downloads from GitHub and serves to agents (proxy model).

**Why Proxy Model:**
- ✅ Corporate firewalls block GitHub
- ✅ Reduces bandwidth (1 download vs N downloads)
- ✅ Backend verifies before distribution (trust boundary)
- ✅ Works in air-gapped environments (manual upload)


### Question 2: When to Update?

| Strategy | Use Case | Risk |
|----------|----------|------|
| **Automatic (forced)** | Critical security patches | Breaking changes |
| **Automatic (opt-in)** | Feature updates | User disruption |
| **Manual trigger** | Controlled rollout | Delayed patches |

**Decision:** Hybrid approach - security patches auto, features manual.

### Question 3: How to Verify Integrity?

| Method | Security Level | Complexity |
|--------|----------------|------------|
| **No verification** | ❌ None | Low |
| **SHA256 checksum** | ✅ Good | Medium |
| **GPG signature** | ✅✅ Better | High |
| **Authenticode (Windows)** | ✅✅✅ Best | Very High |

**Decision:** Start with SHA256, plan for code signing.

---

## 🏗️ System Components

### Architecture Overview

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   GitHub     │◄─────│   Backend    │      │    Agent     │
│  Releases    │      │  (Proxy/CDN) │◄─────│   (Client)   │
└──────────────┘      └──────────────┘      └──────────────┘
       │                     │                      │
       │                     │                      │
       ▼                     ▼                      ▼
  v2.5.0.exe          1. Download from GitHub   1. Check version
  SHA256.txt          2. Verify SHA256          2. Download from Backend
  CHANGELOG.md        3. Store locally          3. Verify SHA256
                      4. Serve to agents        4. Apply update
```

### 1. Backend API

**Endpoint 1:** `GET /api/agent/version/latest`

**Response:**
```json
{
  "version": "2.5.0",
  "release_date": "2026-02-04T10:00:00Z",
  "download_url": "/api/agent/download/2.5.0/windows",
  "sha256": "abc123...",
  "changelog": "Security fixes, performance improvements",
  "critical": false,
  "min_version": "2.0.0"
}
```

**Endpoint 2:** `GET /api/agent/download/{version}/{platform}`

**Response:** Binary stream (agent executable)

**Security Checks:**
- Validate GitHub release exists
- Download and verify checksum BEFORE serving
- Rate limit requests (prevent DoS)
- Log all download attempts

### 2. Agent Update Logic

**File:** `agent/internal/updater/updater.go`

**Flow:**
```
1. Check current version
2. Query backend for latest
3. Compare versions (semver)
4. Download binary from BACKEND (not GitHub)
5. Verify SHA256 checksum
6. Backup current executable
7. Replace with new version
8. Restart service
9. Verify health
10. Report success/failure to backend
```

**Error Handling:**
- Checksum mismatch → Abort, report
- Download failure → Retry 3x with backoff
- Restart failure → Rollback to backup
- Health check fail → Rollback

### 3. Dashboard UI

**Page:** `frontend/src/pages/Updates.jsx`

**Features:**
- View available updates
- Trigger update for agent groups
- Monitor update progress
- Rollback capability
- Update history


---

## 🛡️ Security Implementation Checklist

### Phase 1: Foundation (MVP)

- [ ] **HTTPS Only:** No HTTP fallback
- [ ] **SHA256 Verification:** Mandatory before execution
- [ ] **Backup Before Update:** Keep N-1 version
- [ ] **Health Check:** Verify agent responds after update
- [ ] **Rollback Logic:** Auto-revert on failure

### Phase 2: Hardening

- [ ] **Rate Limiting:** Prevent update storms
- [ ] **Staged Rollout:** Update 10% → 50% → 100%
- [ ] **Circuit Breaker:** Stop if failure rate \u003e 5%
- [ ] **Audit Logging:** Track who triggered updates
- [ ] **Version Pinning:** Prevent downgrade attacks

### Phase 3: Advanced

- [ ] **Code Signing:** GPG or Authenticode
- [ ] **Certificate Pinning:** Prevent MITM
- [ ] **Delta Updates:** Only download changed bytes
- [ ] **A/B Testing:** Canary deployments
- [ ] **Compliance:** SOC2/ISO27001 requirements

---

## 📊 Monitoring & Metrics

### Key Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Update Success Rate** | \u003c 95% | Pause rollout |
| **Download Time** | \u003e 5min | Check CDN |
| **Rollback Rate** | \u003e 5% | Investigate version |
| **Agent Offline Post-Update** | \u003e 2% | Emergency rollback |

### Alerting Rules

```
CRITICAL: Update failure rate \u003e 10% in 15min
HIGH: Rollback triggered on \u003e 50 agents
MEDIUM: Download time \u003e 10min for \u003e 20% agents
```

---

## 🚀 Implementation Phases

### Phase 1: Version Check API (Week 1)

**Backend:**
- Create `internal/services/github_release.go`
- Implement GitHub API client
- Add `/api/agent/version/latest` endpoint
- Cache responses (5min TTL)

**Agent:**
- Add version check on startup
- Log available updates
- NO auto-update yet

**Validation:**
- Agent logs show "Update available: v2.5.0"
- Backend caches GitHub responses

### Phase 2: Manual Update (Week 2)

**Agent:**
- Implement `internal/updater/downloader.go`
- Add SHA256 verification
- Add backup logic
- Add restart mechanism

**Dashboard:**
- Create "Updates" page
- Add "Update Now" button per agent
- Show update status

**Validation:**
- Manual update works on test agent
- Rollback works on simulated failure

### Phase 3: Staged Rollout (Week 3)

**Backend:**
- Add update orchestration logic
- Implement staged rollout (10% → 50% → 100%)
- Add circuit breaker

**Dashboard:**
- Add rollout progress visualization
- Add emergency stop button

**Validation:**
- Update 1000 agents in stages
- Circuit breaker triggers on 5% failure

### Phase 4: Code Signing (Week 4+)

**Build Pipeline:**
- Generate GPG key pair
- Sign releases in CI/CD
- Publish signatures to GitHub

**Agent:**
- Add signature verification
- Reject unsigned binaries

**Validation:**
- Tampered binary rejected
- Valid signature accepted

---

## ⚠️ Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Auto-update without verification | Verify SHA256 minimum |
| Update all agents at once | Staged rollout (10% → 100%) |
| No rollback mechanism | Always keep N-1 version |
| Ignore update failures | Monitor and alert |
| Download over HTTP | HTTPS only |
| Trust GitHub blindly | Verify checksums |
| Update during business hours | Schedule for off-peak |
| No health check post-update | Verify agent responds |

---

## 🔍 Security Validation Checklist

### OWASP A03: Supply Chain

- [ ] Dependencies pinned with lock files
- [ ] GitHub Actions uses pinned versions
- [ ] Release artifacts signed
- [ ] Checksum verification mandatory

### OWASP A08: Integrity Failures

- [ ] No unsigned updates accepted
- [ ] Tampered binaries rejected
- [ ] Rollback on integrity failure
- [ ] Audit trail of all updates

### OWASP A02: Security Misconfiguration

- [ ] HTTPS enforced
- [ ] TLS 1.3 minimum
- [ ] No default credentials
- [ ] Least privilege for update process

### OWASP A10: Exceptional Conditions

- [ ] Download timeout (5min max)
- [ ] Retry limit (3 attempts)
- [ ] Fail-closed on checksum mismatch
- [ ] Rollback on any error

---

## 📝 Implementation Example (Go)

### Updater Interface

```go
type Updater interface {
    CheckForUpdate() (*UpdateInfo, error)
    DownloadUpdate(info *UpdateInfo) (string, error)
    VerifyChecksum(filepath, expectedSHA256 string) error
    BackupCurrent() error
    ApplyUpdate(newBinaryPath string) error
    Rollback() error
    VerifyHealth() error
}
```

### Security-First Download

```go
func (u *Updater) DownloadUpdate(info *UpdateInfo) (string, error) {
    // 1. HTTPS only
    if !strings.HasPrefix(info.DownloadURL, "https://") {
        return "", errors.New("SECURITY: non-HTTPS download rejected")
    }

    // 2. Download to temp with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
    defer cancel()

    resp, err := http.Get(info.DownloadURL)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()

    // 3. Save to temp file
    tmpFile, err := os.CreateTemp("", "rmm-agent-*.exe")
    if err != nil {
        return "", err
    }
    defer tmpFile.Close()

    if _, err := io.Copy(tmpFile, resp.Body); err != nil {
        os.Remove(tmpFile.Name())
        return "", err
    }

    // 4. MANDATORY checksum verification
    if err := u.VerifyChecksum(tmpFile.Name(), info.SHA256); err != nil {
        os.Remove(tmpFile.Name())
        return "", fmt.Errorf("SECURITY: checksum mismatch: %w", err)
    }

    return tmpFile.Name(), nil
}
```

---

## 🎓 Learning Outcomes

After implementing this skill, you should be able to:

1. **Explain** why updates are a critical attack vector
2. **Design** a secure update architecture
3. **Implement** checksum verification
4. **Plan** staged rollout strategies
5. **Monitor** update success rates
6. **Respond** to update failures

---

> **Remember:** Every update is a potential security incident. Design for failure, verify everything, and always have a rollback plan.
