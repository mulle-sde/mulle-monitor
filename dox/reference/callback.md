# callback

Manage callbacks for file system monitoring.

## Synopsis

```bash
mulle-monitor callback [options] <command> [arguments...]
mulle-monitor callback [options] --list
mulle-monitor callback [options] --add <name> <script>
mulle-monitor callback [options] --remove <name>
```

## Description

The `callback` command manages callback scripts that are executed when file system events are detected. Callbacks are short-lived scripts that can optionally trigger tasks. Multiple callbacks can coalesce to one task run if they appear within the sleep period.

The command provides comprehensive callback management including:
- Adding and removing callbacks
- Listing available callbacks
- Testing callback execution
- Managing callback configurations
- Debugging callback behavior

## Options

| Option | Description |
|--------|-------------|
| `-n, --dry-run` | Show what would be done without executing |
| `-v, --verbose` | Enable verbose output |
| `-f, --force` | Force operation without confirmation |
| `-q, --quiet` | Suppress non-error output |
| `-h, --help` | Show help information |

## Commands

### Callback Management

| Command | Description |
|---------|-------------|
| `add` | Add a new callback |
| `remove` | Remove an existing callback |
| `list` | List all available callbacks |
| `show` | Show details of a specific callback |
| `edit` | Edit an existing callback |
| `test` | Test a callback execution |

### Callback Operations

| Command | Description |
|---------|-------------|
| `enable` | Enable a disabled callback |
| `disable` | Disable an enabled callback |
| `rename` | Rename a callback |
| `copy` | Copy a callback to a new name |

## Examples

### Basic Callback Management

```bash
# List all available callbacks
mulle-monitor callback list

# Add a new callback
mulle-monitor callback add build "make all"

# Remove a callback
mulle-monitor callback remove build

# Show details of a callback
mulle-monitor callback show build
```

### Advanced Callback Configuration

```bash
# Add callback with custom options
mulle-monitor callback add --pattern "*.c,*.h" --delay 2s compile "gcc -c *.c"

# Test callback execution
mulle-monitor callback test build

# Edit existing callback
mulle-monitor callback edit build

# Copy callback to new name
mulle-monitor callback copy build build-release
```

### Callback Control

```bash
# Disable a callback temporarily
mulle-monitor callback disable build

# Enable a previously disabled callback
mulle-monitor callback enable build

# Rename a callback
mulle-monitor callback rename build compile
```

## Callback Configuration

Callbacks are configured with the following parameters:

### Basic Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `name` | Unique callback identifier | Yes |
| `script` | Command to execute | Yes |
| `pattern` | File patterns to match | No |
| `delay` | Coalescence delay | No |

### Advanced Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `timeout` | Maximum execution time | 30s |
| `retries` | Number of retry attempts | 0 |
| `priority` | Execution priority | normal |
| `environment` | Environment variables | inherited |
| `working-dir` | Working directory | project root |

## Callback Script Format

Callback scripts can be:
- Shell commands: `"make all"`
- Script files: `"/path/to/build.sh"`
- Complex commands: `"cd /tmp && make clean && make"`

### Script Examples

```bash
# Simple command
"echo 'Files changed, rebuilding...' && make"

# Multi-line script
"/bin/bash -c '
echo \"Starting build...\"
make clean
make all
echo \"Build complete\"
'"

# Conditional execution
"if [ -f Makefile ]; then make; else echo 'No Makefile found'; fi"
```

## Pattern Matching

Callbacks can be triggered by file patterns:

### Pattern Syntax

```bash
# Single pattern
--pattern "*.c"

# Multiple patterns
--pattern "*.c,*.h,*.m"

# Directory patterns
--pattern "src/**"

# Exclude patterns
--pattern "*.c" --exclude "test/**"
```

### Pattern Examples

```bash
# Source files
--pattern "*.c,*.cpp,*.h,*.hpp"

# Configuration files
--pattern "*.json,*.yaml,*.yml,*.conf"

# Documentation
--pattern "*.md,*.txt,README*"

# All files except certain directories
--pattern "**" --exclude "node_modules/**,.git/**"
```

## Callback Execution

### Execution Context

Callbacks execute with:
- Current working directory set to project root
- Environment variables from parent process
- Standard input/output/error streams
- Timeout protection

### Execution Flow

1. **Trigger Detection**: File system event matches callback pattern
2. **Coalescence Check**: Wait for sleep period to allow multiple events
3. **Callback Execution**: Run callback script
4. **Task Triggering**: Optionally trigger associated task
5. **Result Handling**: Process execution results

### Execution Results

| Result | Description | Action |
|--------|-------------|--------|
| `0` | Success | Continue normally |
| `1-127` | Script error | Log error, continue |
| `128+` | Signal termination | Log signal, retry if configured |
| `timeout` | Execution timeout | Terminate, retry if configured |

## Integration with Tasks

Callbacks can trigger tasks for long-running operations:

```bash
# Callback triggers task
mulle-monitor callback add build "echo 'Build triggered'" --task build-all

# Task definition
mulle-monitor task add build-all "make clean && make && make test"
```

### Callback-Task Relationship

- **Callbacks**: Short, frequent operations (< 30 seconds)
- **Tasks**: Long, resource-intensive operations (> 30 seconds)
- **Coalescence**: Multiple callbacks can trigger one task
- **Priority**: Tasks have higher priority than callbacks

## Debugging Callbacks

### Debug Options

```bash
# Enable verbose callback logging
mulle-monitor callback --verbose list

# Test callback with debug output
mulle-monitor callback --debug test build

# Show callback execution trace
mulle-monitor callback --trace run build
```

### Debug Output

```
[DEBUG] Callback 'build' triggered by file: src/main.c
[DEBUG] Pattern match: *.c
[DEBUG] Coalescence delay: 1.0s
[DEBUG] Executing: make all
[DEBUG] Execution time: 2.3s
[DEBUG] Exit code: 0
[DEBUG] Task 'build-all' triggered
```

## Callback Storage

Callbacks are stored in:
- **Configuration files**: `/etc/mulle-monitor/callbacks/`
- **User files**: `~/.mulle-monitor/callbacks/`
- **Project files**: `.mulle-monitor/callbacks/`

### Storage Format

```json
{
  "name": "build",
  "script": "make all",
  "pattern": "*.c,*.h",
  "delay": "1s",
  "timeout": "30s",
  "enabled": true,
  "task": "build-all"
}
```

## Best Practices

### Callback Design

1. **Keep callbacks short**: < 30 seconds execution time
2. **Use specific patterns**: Avoid overly broad patterns
3. **Handle errors gracefully**: Check exit codes and handle failures
4. **Use appropriate delays**: Balance responsiveness vs. coalescence
5. **Test thoroughly**: Verify callback behavior before deployment

### Performance Considerations

- **Pattern specificity**: Broad patterns increase CPU usage
- **Delay optimization**: Longer delays reduce execution frequency
- **Resource limits**: Set appropriate timeouts and memory limits
- **Caching**: Use file system caching for large projects

### Security Considerations

- **Path validation**: Validate all file paths
- **Command sanitization**: Sanitize user input in scripts
- **Permission checks**: Verify execution permissions
- **Resource limits**: Prevent resource exhaustion

## Exit Status

- `0` - Callback operation successful
- `1` - Callback not found
- `2` - Invalid callback configuration
- `3` - Callback execution failed
- `4` - Permission denied

## Files

- `/etc/mulle-monitor/callbacks/` - System callback configurations
- `~/.mulle-monitor/callbacks/` - User callback configurations
- `.mulle-monitor/callbacks/` - Project callback configurations

## See Also

- [`task`](task.md) - Manage tasks triggered by callbacks
- [`patternfile`](patternfile.md) - Manage pattern files for matching
- [`run`](run.md) - Start the file system monitor