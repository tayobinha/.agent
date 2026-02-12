#!/usr/bin/env python3
"""
RMM SaaS - Comprehensive Pre-Launch Checklist
Executes all validation scripts in priority order
"""

import subprocess
import sys
import os
from pathlib import Path

# Priority-based execution order
CHECKS = [
    # P0: Critical Security
    {
        "name": "Security Scan",
        "script": ".agent/skills/vulnerability-scanner/scripts/security_scan.py",
        "priority": "P0",
        "required": True
    },
    {
        "name": "Dependency Analysis",
        "script": ".agent/skills/vulnerability-scanner/scripts/dependency_analyzer.py",
        "priority": "P0",
        "required": True
    },
    
    # P1: Code Quality
    {
        "name": "Lint Check",
        "script": ".agent/skills/lint-and-validate/scripts/lint_runner.py",
        "priority": "P1",
        "required": True
    },
    
    # P2: Database
    {
        "name": "Schema Validation",
        "script": ".agent/skills/database-design/scripts/schema_validator.py",
        "priority": "P2",
        "required": False
    },
    
    # P3: Testing
    {
        "name": "Test Runner",
        "script": ".agent/skills/testing-patterns/scripts/test_runner.py",
        "priority": "P3",
        "required": False
    },
    
    # P4: Frontend
    {
        "name": "UX Audit",
        "script": ".agent/skills/frontend-design/scripts/ux_audit.py",
        "priority": "P4",
        "required": False
    },
    {
        "name": "Accessibility Check",
        "script": ".agent/skills/frontend-design/scripts/accessibility_checker.py",
        "priority": "P4",
        "required": False
    },
    
    # P5: SEO
    {
        "name": "SEO Checker",
        "script": ".agent/skills/seo-fundamentals/scripts/seo_checker.py",
        "priority": "P5",
        "required": False
    },
]

def run_check(check, project_path):
    """Execute a single check"""
    script_path = Path(project_path) / check["script"]
    
    if not script_path.exists():
        print(f"⚠️  {check['name']}: Script not found (skipping)")
        return "SKIP"
    
    print(f"\n{'='*60}")
    print(f"Running: {check['name']} ({check['priority']})")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(
            [sys.executable, str(script_path), project_path],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        
        if result.returncode == 0:
            print(f"✅ {check['name']}: PASSED")
            return "PASS"
        else:
            print(f"❌ {check['name']}: FAILED (exit code: {result.returncode})")
            return "FAIL"
            
    except subprocess.TimeoutExpired:
        print(f"⏱️  {check['name']}: TIMEOUT")
        return "TIMEOUT"
    except Exception as e:
        print(f"💥 {check['name']}: ERROR - {e}")
        return "ERROR"

def main():
    if len(sys.argv) < 2:
        print("Usage: python checklist.py <project_path>")
        sys.exit(1)
    
    project_path = sys.argv[1]
    
    print("🚀 RMM SaaS - Pre-Launch Checklist")
    print(f"Project: {project_path}\n")
    
    results = {}
    critical_failures = []
    
    for check in CHECKS:
        result = run_check(check, project_path)
        results[check["name"]] = result
        
        if result == "FAIL" and check["required"]:
            critical_failures.append(check["name"])
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    
    passed = sum(1 for r in results.values() if r == "PASS")
    failed = sum(1 for r in results.values() if r == "FAIL")
    skipped = sum(1 for r in results.values() if r == "SKIP")
    
    print(f"✅ Passed:  {passed}/{len(CHECKS)}")
    print(f"❌ Failed:  {failed}/{len(CHECKS)}")
    print(f"⚠️  Skipped: {skipped}/{len(CHECKS)}")
    
    if critical_failures:
        print(f"\n🔴 CRITICAL FAILURES:")
        for failure in critical_failures:
            print(f"   - {failure}")
        print("\n❌ NOT READY FOR PRODUCTION")
        sys.exit(1)
    else:
        print("\n✅ ALL CRITICAL CHECKS PASSED")
        if failed > 0:
            print("⚠️  Some non-critical checks failed. Review recommended.")
        sys.exit(0)

if __name__ == "__main__":
    main()
