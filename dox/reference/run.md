# run

Start the file system monitor to watch for changes and execute callbacks.

## Synopsis

```bash
mulle-monitor run [options] [patternfile...]
mulle-monitor run [options] --patternfile <file>
mulle-monitor run [options] --callback <name>
```

## Description

The `run` command starts the file system monitoring daemon that watches for file system events and executes configured callbacks when matching patterns are detected. This is the primary command for operating mulle-monitor.

The monitor can watch specific files, directories, or use pattern files to define complex matching rules. When file changes are detected, callbacks are executed, which can optionally trigger tasks for long-running operations.

## Options

| Option | Description |
|--------|-------------|
| `-f, --foreground` | Run in foreground (don't daemonize) |
| `-d, --daemon` | Run as daemon in background |
| `-v, --verbose` | Enable verbose output |
| `-q, --quiet` | Suppress non-error output |
| `-n, --dry-run` | Show what would be done without monitoring |
| `-h, --help` | Show help information |

### Monitoring Options

| Option | Description |
|--------|-------------|
| `--sleep <delay>` | Time to coalesce multiple events (default: 1s) |
| `--pattern <pattern>` | File pattern to monitor |
| `--exclude <pattern>` | Pattern to exclude from monitoring |
| `--callback <name>` | Specific callback to use |
| `--task <name>` | Task to trigger on events |

### Control Options

| Option | Description |
|--------|-------------|
| `--pid-file <file>` | Write PID to specified file |
| `--log-file <file>` | Write log output to file |
| `--config <file>` | Use specific configuration file |
| `--no-preempt` | Disable preemptive callback execution |

## Examples

### Basic Monitoring

```bash
# Monitor current directory
mulle-monitor run

# Monitor specific directory
mulle-monitor run /path/to/project

# Monitor with specific pattern
mulle-monitor run --pattern "*.c,*.h"
```

### Advanced Monitoring

```bash
# Monitor with custom sleep delay
mulle-monitor run --sleep 2s

# Monitor excluding certain files
mulle-monitor run --exclude "build/**,*.tmp"

# Monitor with specific callback
mulle-monitor run --callback build

# Monitor and trigger specific task
mulle-monitor run --task compile
```

### Daemon Mode

```bash
# Run as daemon
mulle-monitor run --daemon

# Run as daemon with PID file
mulle-monitor run --daemon --pid-file /var/run/mulle-monitor.pid

# Run as daemon with logging
mulle-monitor run --daemon --log-file /var/log/mulle-monitor.log
```

### Pattern File Usage

```bash
# Use specific pattern file
mulle-monitor run --patternfile build.patterns

# Use multiple pattern files
mulle-monitor run build.patterns test.patterns

# Combine with additional patterns
mulle-monitor run --patternfile build.patterns --pattern "*.md"
```

## Pattern Files

Pattern files define which files to monitor and which callbacks to execute:

### Pattern File Format

```
# Include patterns (files to monitor)
*.c
*.h
*.m
src/**

# Exclude patterns (files to ignore)
!build/**
!*.tmp
!.git/**

# Callback assignments
*.c     : build
*.h     : build
*.md    : docs
```

### Pattern Syntax

| Pattern | Description | Example |
|---------|-------------|---------|
| `*` | Match any characters except `/` | `*.c` |
| `**` | Match any characters including `/` | `src/**` |
| `?` | Match single character | `file?.txt` |
| `[abc]` | Match any character in set | `file[123].txt` |
| `{a,b}` | Match either pattern | `*.{c,h}` |
| `!` | Exclude pattern | `!build/**` |

## Monitoring Behavior

### Event Detection

The monitor detects various file system events:

- **File Creation**: New files added
- **File Modification**: Existing files changed
- **File Deletion**: Files removed
- **Directory Changes**: Directory structure changes
- **Attribute Changes**: File permissions/metadata changes

### Event Coalescence

Multiple events within the sleep period are coalesced:

```bash
# Events within 1 second are grouped
touch file1.c    # Event 1
touch file2.c    # Event 2 (within 1s)
sleep 1
touch file3.c    # Event 3 (after 1s)
```

Result: Two callback executions (events 1+2, then event 3)

### Callback Execution

Callbacks are executed in the following order:

1. **Pattern Matching**: Check if file matches callback patterns
2. **Callback Selection**: Select appropriate callback
3. **Environment Setup**: Set up execution environment
4. **Script Execution**: Run callback script
5. **Result Processing**: Handle execution results
6. **Task Triggering**: Optionally trigger associated task

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MULLE_MONITOR_SLEEP_TIME` | Default sleep delay | `1` |
| `MULLE_MONITOR_PID_FILE` | PID file location | None |
| `MULLE_MONITOR_LOG_FILE` | Log file location | None |
| `MULLE_MONITOR_CONFIG_DIR` | Configuration directory | `~/.mulle-monitor` |

### Configuration Files

Configuration is read from multiple locations (in order):

1. System configuration: `/etc/mulle-monitor/`
2. User configuration: `~/.mulle-monitor/`
3. Project configuration: `.mulle-monitor/`
4. Command-line options (highest priority)

## Signal Handling

The monitor responds to standard signals:

| Signal | Action |
|--------|--------|
| `TERM` | Graceful shutdown |
| `INT` | Immediate shutdown |
| `HUP` | Reload configuration |
| `USR1` | Increase verbosity |
| `USR2` | Decrease verbosity |

## Performance Considerations

### Resource Usage

- **Memory**: ~10-50MB depending on number of patterns
- **CPU**: Minimal when idle, spikes during callback execution
- **Disk I/O**: Reads pattern files and configuration

### Optimization Tips

1. **Use specific patterns**: Avoid overly broad patterns like `**`
2. **Set appropriate sleep times**: Balance responsiveness vs. coalescence
3. **Limit concurrent callbacks**: Use task queuing for heavy operations
4. **Monitor specific directories**: Avoid monitoring entire file systems

### Scaling Considerations

For large projects:
- Use pattern files instead of command-line patterns
- Implement callback prioritization
- Consider distributed monitoring setups
- Use task queues for heavy processing

## Troubleshooting

### Common Issues

**Monitor not detecting changes:**
```bash
# Check if directory is being monitored
mulle-monitor run --verbose /path/to/dir

# Verify file system events are working
touch test.file && mulle-monitor run --dry-run
```

**Callbacks not executing:**
```bash
# Test callback directly
mulle-monitor callback test build

# Check callback configuration
mulle-monitor callback show build
```

**High CPU usage:**
```bash
# Reduce sleep time
mulle-monitor run --sleep 0.1s

# Use more specific patterns
mulle-monitor run --pattern "src/*.c" --exclude "src/test/**"
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Verbose output
mulle-monitor run --verbose

# Debug callback execution
mulle-monitor run --debug-callbacks

# Log to file
mulle-monitor run --log-file debug.log
```

## Integration Examples

### Build System Integration

```bash
# Monitor source files and trigger build
mulle-monitor run --pattern "*.c,*.h" --callback build

# Monitor documentation and regenerate
mulle-monitor run --pattern "*.md" --callback docs
```

### Development Workflow

```bash
# Monitor and run tests
mulle-monitor run --pattern "src/**,test/**" --callback test

# Monitor configuration files
mulle-monitor run --pattern "*.json,*.yaml" --callback reload
```

### CI/CD Integration

```bash
# Trigger CI pipeline on changes
mulle-monitor run --pattern "src/**" --callback ci-trigger

# Monitor deployment files
mulle-monitor run --pattern "deploy/**" --callback deploy
```

## Exit Status

- `0` - Monitor completed successfully
- `1` - Configuration error
- `2` - File system access error
- `3` - Callback execution error
- `4` - Signal received

## Files

- `~/.mulle-monitor/patterns/` - User pattern files
- `~/.mulle-monitor/callbacks/` - User callback configurations
- `~/.mulle-monitor/tasks/` - User task definitions
- `/var/run/mulle-monitor.pid` - PID file (when specified)
- `/var/log/mulle-monitor.log` - Log file (when specified)

## See Also

- [`callback`](callback.md) - Manage callbacks
- [`task`](task.md) - Manage tasks
- [`patternfile`](patternfile.md) - Manage pattern files