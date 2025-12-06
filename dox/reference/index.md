# mulle-monitor Command Reference

## Overview

**mulle-monitor** is a cross-platform command-line tool for monitoring system services, applications, and infrastructure components. It provides real-time monitoring capabilities with alerting, logging, and analysis features for system administrators and developers.

## Command Categories

### Core Monitoring
- **[`monitor`](monitor.md)** - Start monitoring services and applications
- **[`status`](status.md)** - Show current monitoring status
- **[`check`](check.md)** - Perform health checks on monitored services
- **[`alert`](alert.md)** - Manage alert configurations and notifications

### Monitoring Operations
- **[`watch`](watch.md)** - Watch specific services or processes
- **[`track`](track.md)** - Track performance metrics and trends
- **[`analyze`](analyze.md)** - Analyze monitoring data and generate reports

### Configuration & Info
- **[`config`](config.md)** - Manage monitoring configuration
- **[`info`](info.md)** - Show system and monitoring information
- **[`list`](list.md)** - List monitored services and components
- **[`log`](log.md)** - Show monitoring logs and history

## Quick Start Examples

### Basic Monitoring Operations
```bash
# Start monitoring a service
mulle-monitor monitor "nginx"

# Check service health
mulle-monitor check "web-server"

# Get monitoring status
mulle-monitor status

# Set up alerts for a service
mulle-monitor alert "database" --threshold 90
```

### Service Management
```bash
# Watch a specific process
mulle-monitor watch "apache2"

# Track performance metrics
mulle-monitor track "cpu-usage"

# Analyze monitoring data
mulle-monitor analyze --last-hour

# View monitoring logs
mulle-monitor log --tail
```

### Configuration and Setup
```bash
# Configure monitoring settings
mulle-monitor config set interval 30

# List all monitored services
mulle-monitor list

# Get detailed system info
mulle-monitor info

# Export monitoring data
mulle-monitor analyze --export-json
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `monitor` | Core | Start monitoring services and applications |
| `status` | Core | Show current monitoring status |
| `check` | Core | Perform health checks |
| `alert` | Core | Manage alert configurations |
| `watch` | Operations | Watch specific services or processes |
| `track` | Operations | Track performance metrics |
| `analyze` | Operations | Analyze monitoring data |
| `config` | Configuration | Manage monitoring configuration |
| `info` | Configuration | Show system information |
| `list` | Configuration | List monitored services |
| `log` | Configuration | Show monitoring logs |

## Getting Help

### Command Help
```bash
# Get help for specific command
mulle-monitor <command> --help

# List all available commands
mulle-monitor --help

# Get detailed help with examples
mulle-monitor <command> --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check `mulle-monitor status` for current monitoring state

## Common Workflows

### Initial Monitoring Setup
1. **Configure** monitoring: `mulle-monitor config init`
2. **Add** services to monitor: `mulle-monitor monitor <service>`
3. **Set up** alerts: `mulle-monitor alert <service> --threshold <value>`
4. **Verify** status: `mulle-monitor status`

### Service Monitoring
1. **Start** monitoring: `mulle-monitor monitor <service>`
2. **Check** health: `mulle-monitor check <service>`
3. **Review** alerts: `mulle-monitor alert list`
4. **Analyze** performance: `mulle-monitor analyze <service>`

### Troubleshooting
1. **Check** service status: `mulle-monitor status <service>`
2. **Review** logs: `mulle-monitor log <service> --last-24h`
3. **Run** diagnostics: `mulle-monitor check <service> --verbose`
4. **Analyze** issues: `mulle-monitor analyze <service> --troubleshoot`

## Troubleshooting

### Monitoring Failures
```bash
# Check monitoring service status
mulle-monitor status

# Run verbose health check
mulle-monitor check --verbose <service>

# Clear monitoring cache and restart
mulle-monitor config clear-cache
mulle-monitor monitor restart
```

### Alert Issues
```bash
# Check alert configuration
mulle-monitor alert list

# Test alert notifications
mulle-monitor alert test <alert-id>

# Review alert history
mulle-monitor log --alerts --last-week
```

### Performance Problems
```bash
# Check system resources
mulle-monitor info --system

# Analyze performance metrics
mulle-monitor analyze --performance --last-day

# Review monitoring logs
mulle-monitor log --performance --tail
```

## Advanced Usage

### Custom Monitoring Options
```bash
# Monitor with custom interval
mulle-monitor monitor <service> --interval 60

# Set custom alert thresholds
mulle-monitor alert <service> --cpu-threshold 80 --memory-threshold 90

# Monitor multiple services
mulle-monitor monitor service1 service2 service3
```

### Environment Configuration
```bash
# Custom log directory
export MULLE_MONITOR_LOG_DIR="/var/log/monitor"

# Custom configuration file
export MULLE_MONITOR_CONFIG="/etc/monitor/config.json"

# Custom alert endpoints
export MULLE_MONITOR_ALERT_WEBHOOK="https://hooks.slack.com/..."
```

### Advanced Analysis
```bash
# Generate performance report
mulle-monitor analyze --report --output report.html

# Export metrics to external system
mulle-monitor track --export-prometheus

# Custom analysis queries
mulle-monitor analyze --query "cpu > 90 AND memory > 85"
```

## Related Documentation

- **[TODO.md](../TODO.md)** - Documentation creation process and guidelines
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines