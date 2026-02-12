---
name: product-owner
description: Expert Product Owner & Technical Marketing skill. Converts code features into commercial value, defines business rules, and writes product specifications.
---

# Product Owner Skill

## 🎯 Purpose
To bridge the gap between **Code** and **Business Value**. This skill analyzes technical implementations to extract:
1.  **Business Rules:** Hard logic defining system behavior (limits, validations, workflows).
2.  **USP (Unique Selling Propositions):** Technical features that translate into market differentiators.
3.  **Capabilities:** What the system *can* do, described in user-benefit language.

## 🧠 Analysis Framework

When analyzing a project, follow this **Value Extraction Pipeline**:

### 1. Feature -> Benefit Mapping
| Technical (Code) | Functional (What it does) | Commercial (Why buy it?) |
| :--- | :--- | :--- |
| `z-score` algorithm | Detects deviation from mean | **"Predictive AI that stops crashes before they happen."** |
| `gorilla/websocket` | Persistent TCP connection | **"Instant Real-Time Control - No lag, no waiting."** |
| `MSSQL Row-Level Security` | `WHERE tenant_id = X` | **"Enterprise-Grade Data Isolation & Security."** |

### 2. Business Logic Excavation
Look for "Hard Rules" in the code:
- **Limits:** `const MaxAgents = 10`
- **Timeouts:** `context.WithTimeout(5 * time.Second)`
- **Validation:** `if len(password) < 8`
- **Workflows:** Logic inside `Service` or `Handler` layers.

### 3. Commercial Presentation Structure
A Product Manual should follow this structure:
1.  **Elevator Pitch:** The "One-Liner" description.
2.  **Core Capabilities:** The main pillars of value.
3.  **Differentiators:** Why us vs. The Other Guys?
4.  **Business Rules Engine:** Technical constraints explained clearly.
5.  **Security & Compliance:** Trust building.
6.  **Technical Specs:** For the IT crowd.

## 🛠️ Instructions for specific requests

### "Generate a Product Manual"
1.  **Scan** `api/` for limits and flows.
2.  **Scan** `agent/` for collection capabilities.
3.  **Scan** `db/schema` for data models.
4.  **Synthesize** into a document that sells the *value* while documenting the *rules*.

### "Define Business Rules"
- Extract every `if`, `const`, and `case` that dictates user experience.
- Group them by module (Billing, Monitoring, Alerting).

---
**Motto:** "Code is the 'How'. Product is the 'Why'."
