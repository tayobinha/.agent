---
name: performance-monitoring
description: Performance monitoring principles and patterns for RMM agents. Efficient metric collection, throttling strategies, and impact minimization techniques.
---

# Performance Monitoring Skill

## Purpose

This skill provides principles and patterns for implementing **efficient performance monitoring** in RMM agents without degrading system performance.

**Core Principles:**
1. **Measure First:** Profile before optimizing
2. **Throttle Wisely:** Not all metrics need real-time collection
3. **Batch Operations:** Group syscalls to reduce overhead
4. **Fail Gracefully:** Monitoring should never crash the agent

---

## Key Concepts

### 1. Metric Collection Tiers

**Tier 1: Lightweight (Every Poll)**
- CPU, RAM, Disk usage (global)
- Network stats
- Uptime

**Impact:** ~10 syscalls, <0.5% CPU

**Tier 2: Medium (2x Poll Interval)**
- Disk I/O rates
- Per-process CPU/RAM
- Network I/O per interface

**Impact:** ~30 syscalls, <1% CPU

**Tier 3: Heavy (On-Demand)**
- Full process tree
- Detailed I/O per process
- System call tracing

**Impact:** >100 syscalls, >2% CPU

---

### 2. Throttling Strategies

#### Time-Based Throttling

```go
type MetricCollector struct {
    lastCollection time.Time
    interval       time.Duration
}

func (m *MetricCollector) ShouldCollect() bool {
    return time.Since(m.lastCollection) >= m.interval
}
```

**Use When:** Metrics change slowly (e.g., disk I/O trends)

#### Adaptive Throttling

```go
func (m *MetricCollector) ShouldCollect() bool {
    // Collect more frequently if system is under load
    if systemCPU > 80 {
        return time.Since(m.lastCollection) >= m.interval * 2
    }
    return time.Since(m.lastCollection) >= m.interval
}
```

**Use When:** Agent must reduce its own footprint under load

#### Sampling

```go
func collectProcessMetrics(processes []Process) []ProcessMetric {
    var metrics []ProcessMetric
    for _, proc := range processes {
        // Only collect if process is "interesting"
        if proc.CPUPercent > 1.0 || proc.MemoryMB > 100 {
            metrics = append(metrics, collectMetric(proc))
        }
    }
    return metrics
}
```

**Use When:** Monitoring many processes (>20)

---

### 3. Batching and Caching

#### Batch Syscalls

```go
// BAD: 3 syscalls per process
for _, proc := range processes {
    cpu := proc.CPUPercent()
    mem := proc.MemoryInfo()
    io := proc.IOCounters()
}

// GOOD: 1 syscall for all processes
allProcs := process.Processes()
for _, proc := range allProcs {
    // Data already cached in proc object
    cpu := proc.CPUPercent()
}
```

#### Cache Results

```go
type CachedMetric struct {
    value      float64
    collectedAt time.Time
    ttl        time.Duration
}

func (c *CachedMetric) Get() (float64, bool) {
    if time.Since(c.collectedAt) < c.ttl {
        return c.value, true // Cache hit
    }
    return 0, false // Cache miss
}
```

**TTL Guidelines:**
- CPU/RAM: 5s
- Disk I/O: 10s
- Process list: 30s

---

### 4. Error Handling

#### Fail-Safe Collection

```go
func collectMetricSafely() (float64, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()
    
    resultChan := make(chan float64, 1)
    errChan := make(chan error, 1)
    
    go func() {
        value, err := collectMetric()
        if err != nil {
            errChan <- err
            return
        }
        resultChan <- value
    }()
    
    select {
    case value := <-resultChan:
        return value, nil
    case err := <-errChan:
        return 0, err
    case <-ctx.Done():
        return 0, fmt.Errorf("timeout collecting metric")
    }
}
```

**Principle:** Never let a stuck syscall block the agent

---

## Implementation Patterns

### Pattern 1: Disk I/O Monitoring

**Goal:** Track read/write rates without impacting performance

```go
type DiskIOMonitor struct {
    lastCounters disk.IOCountersStat
    lastCheck    time.Time
}

func (d *DiskIOMonitor) GetRates() (readMBps, writeMBps float64, err error) {
    current, err := disk.IOCounters()
    if err != nil {
        return 0, 0, err
    }
    
    if d.lastCheck.IsZero() {
        d.lastCounters = current
        d.lastCheck = time.Now()
        return 0, 0, nil // First run, no delta
    }
    
    elapsed := time.Since(d.lastCheck).Seconds()
    
    // Calculate delta
    readBytes := current.ReadBytes - d.lastCounters.ReadBytes
    writeBytes := current.WriteBytes - d.lastCounters.WriteBytes
    
    // Convert to MB/s
    readMBps = float64(readBytes) / elapsed / 1024 / 1024
    writeMBps = float64(writeBytes) / elapsed / 1024 / 1024
    
    // Update state
    d.lastCounters = current
    d.lastCheck = time.Now()
    
    return readMBps, writeMBps, nil
}
```

**Impact:** 1 syscall per collection, <0.1% CPU

---

### Pattern 2: Per-Process Monitoring with Throttling

**Goal:** Monitor specific processes without overwhelming the system

```go
type ProcessMonitor struct {
    targetProcesses []string
    lastCollection  time.Time
    throttleInterval time.Duration
    maxProcesses    int
}

func (p *ProcessMonitor) CollectMetrics() ([]ProcessMetric, error) {
    // Throttle: only collect every N seconds
    if !p.shouldCollect() {
        return nil, nil
    }
    
    allProcs, err := process.Processes()
    if err != nil {
        return nil, err
    }
    
    var metrics []ProcessMetric
    collected := 0
    
    for _, proc := range allProcs {
        if collected >= p.maxProcesses {
            break // Limit reached
        }
        
        name, _ := proc.Name()
        if !p.isTargetProcess(name) {
            continue
        }
        
        // Collect metrics
        cpu, _ := proc.CPUPercent()
        mem, _ := proc.MemoryInfo()
        io, _ := proc.IOCounters()
        
        // Only include if "interesting"
        if cpu > 1.0 || mem.RSS > 100*1024*1024 {
            metrics = append(metrics, ProcessMetric{
                Name:      name,
                PID:       proc.Pid,
                CPUPercent: cpu,
                MemoryMB:  float64(mem.RSS) / 1024 / 1024,
                DiskReadMBps: calculateRate(io.ReadBytes),
                DiskWriteMBps: calculateRate(io.WriteBytes),
            })
            collected++
        }
    }
    
    p.lastCollection = time.Now()
    return metrics, nil
}

func (p *ProcessMonitor) shouldCollect() bool {
    return time.Since(p.lastCollection) >= p.throttleInterval
}
```

**Impact:** ~30 syscalls per collection (10 processes), <1% CPU

---

### Pattern 3: Adaptive Collection

**Goal:** Reduce agent footprint when system is under load

```go
type AdaptiveCollector struct {
    normalInterval time.Duration
    reducedInterval time.Duration
    systemCPUThreshold float64
}

func (a *AdaptiveCollector) GetInterval() time.Duration {
    systemCPU, _ := cpu.Percent(0, false)
    
    if len(systemCPU) > 0 && systemCPU[0] > a.systemCPUThreshold {
        // System under load, reduce collection frequency
        return a.reducedInterval
    }
    
    return a.normalInterval
}
```

**Example:**
- Normal: Collect every 10s
- Under load (CPU >80%): Collect every 30s

---

## Performance Benchmarks

### Disk I/O Collection

| Metric | Value |
|--------|-------|
| Syscalls | 1 |
| CPU | <0.1% |
| Memory | <1 MB |
| Latency | <5ms |

### Per-Process Collection (10 processes)

| Metric | Value |
|--------|-------|
| Syscalls | ~30 |
| CPU | <1% |
| Memory | <5 MB |
| Latency | <50ms |

### Full System Scan (100 processes)

| Metric | Value |
|--------|-------|
| Syscalls | ~300 |
| CPU | 2-5% |
| Memory | <10 MB |
| Latency | <200ms |

---

## Best Practices

### DO ✅

1. **Profile First:** Measure impact before deploying
2. **Set Limits:** Max processes, max collection frequency
3. **Use Timeouts:** Prevent stuck syscalls
4. **Cache Aggressively:** Reuse data within TTL
5. **Batch Operations:** Group related syscalls
6. **Fail Gracefully:** Return partial data on error
7. **Monitor Yourself:** Track agent's own resource usage

### DON'T ❌

1. **Don't Block:** Never block main loop on metrics
2. **Don't Collect Everything:** Only monitor what's needed
3. **Don't Ignore Errors:** Log and handle gracefully
4. **Don't Hardcode:** Make thresholds configurable
5. **Don't Trust Syscalls:** Always use timeouts
6. **Don't Spam Network:** Batch before sending
7. **Don't Forget Cleanup:** Close handles, free memory

---

## Configuration Guidelines

### Recommended Defaults

```go
const (
    // Global metrics (lightweight)
    GlobalMetricsInterval = 5 * time.Second
    
    // Disk I/O (medium)
    DiskIOInterval = 10 * time.Second
    
    // Per-process (heavy)
    ProcessMetricsInterval = 20 * time.Second
    MaxMonitoredProcesses = 20
    
    // Thresholds
    ProcessCPUThreshold = 1.0  // Only collect if >1% CPU
    ProcessMemThreshold = 100  // Only collect if >100MB RAM
    
    // Timeouts
    MetricCollectionTimeout = 2 * time.Second
    
    // Cache TTLs
    CPUCacheTTL = 5 * time.Second
    ProcessListCacheTTL = 30 * time.Second
)
```

---

## Troubleshooting

### High Agent CPU Usage

**Symptoms:** Agent using >5% CPU

**Diagnosis:**
1. Check collection intervals (too frequent?)
2. Count monitored processes (>20?)
3. Profile with pprof

**Solutions:**
- Increase throttle intervals
- Reduce max processes
- Enable adaptive collection

### Memory Leaks

**Symptoms:** Agent memory growing over time

**Diagnosis:**
1. Check for unclosed process handles
2. Look for unbounded slices
3. Profile with pprof (heap)

**Solutions:**
- Close process handles after use
- Limit slice sizes
- Add periodic GC hints

### Slow Metrics Collection

**Symptoms:** Collection taking >1s

**Diagnosis:**
1. Check for blocking syscalls
2. Look for missing timeouts
3. Profile with pprof (CPU)

**Solutions:**
- Add timeouts to all syscalls
- Use goroutines for parallel collection
- Cache more aggressively

---

## Testing Strategies

### Unit Tests

```go
func TestDiskIOMonitor(t *testing.T) {
    monitor := &DiskIOMonitor{}
    
    // First call should return 0 (no baseline)
    read, write, err := monitor.GetRates()
    assert.NoError(t, err)
    assert.Equal(t, 0.0, read)
    
    // Simulate some I/O
    time.Sleep(1 * time.Second)
    
    // Second call should return rates
    read, write, err = monitor.GetRates()
    assert.NoError(t, err)
    assert.True(t, read >= 0)
}
```

### Load Tests

```go
func BenchmarkProcessCollection(b *testing.B) {
    monitor := &ProcessMonitor{
        maxProcesses: 10,
    }
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        monitor.CollectMetrics()
    }
}
```

### Integration Tests

- Deploy to test environment
- Monitor for 24h
- Check agent CPU/RAM usage
- Verify no memory leaks

---

## References

- [gopsutil Documentation](https://github.com/shirou/gopsutil)
- [Go Profiling Guide](https://go.dev/blog/pprof)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

---

## Summary

**Key Takeaways:**
1. **Throttle:** Not all metrics need real-time collection
2. **Batch:** Group syscalls to reduce overhead
3. **Cache:** Reuse data within TTL
4. **Limit:** Set max processes and collection frequency
5. **Adapt:** Reduce footprint when system is under load
6. **Fail Safe:** Never let monitoring crash the agent

**Performance Targets:**
- Agent CPU: <1% average, <3% peak
- Agent RAM: <20 MB
- Collection latency: <100ms
- Network overhead: <5 KB/poll
