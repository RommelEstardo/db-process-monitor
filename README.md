# db_process_monitor

# sp_GetActiveProcesses

A comprehensive SQL Server stored procedure for monitoring active database processes and identifying blocking chains in real-time.

## Overview

`sp_GetActiveProcesses` is a diagnostic tool that provides detailed information about active sessions and their resource usage in SQL Server. It's particularly useful for:

- Performance monitoring and troubleshooting
- Identifying blocking issues and their root causes
- Resource usage analysis
- Session activity monitoring
- Query performance investigation

## Features

The procedure provides two main sets of information:

1. **Active Process Details** including:
   - Session information (ID, database, login, host, program)
   - Transaction isolation levels
   - Timing metrics (login time, request start time, elapsed time)
   - Resource usage (CPU, memory, I/O operations)
   - Query details (current statement, full query text, execution plan)
   - Blocking information
   - Wait statistics
   - Process type and status

2. **Blocking Chain Analysis** which:
   - Automatically detects blocking scenarios
   - Visualizes blocking chains in a hierarchical format
   - Shows blocking levels and relationships

## Installation

1. Execute the provided SQL script in your target database:
```sql
USE [YourDatabase]
GO
-- Full procedure creation script here
```

## Usage

Simply execute the stored procedure:
```sql
EXEC sp_GetActiveProcesses
```

## Output Columns

### Main Result Set
- `session_id`: Unique identifier for the session
- `DatabaseName`: Name of the database being accessed
- `LoginName`: SQL Server login name
- `HostName`: Client machine name
- `ProgramName`: Application name
- `IsolationLevel`: Transaction isolation level
- `LoginTime`: Session start time
- `LastRequestStartTime`: Most recent request start time
- `ElapsedMinutes`: Duration of current request
- `CPUMinutes`: CPU time used
- `LogicalReadGB`: Logical reads in GB
- `PhysicalReadGB`: Physical reads in GB
- `WritesGB`: Data written in GB
- `RowCount`: Number of rows processed
- `GrantedMemoryMB`: Memory granted to query
- `BlockingSessionID`: ID of session causing blocking (if any)
- `CurrentStatement`: Currently executing SQL statement
- `FullQueryText`: Complete SQL batch
- `QueryPlan`: Execution plan XML
- `status`: Session status
- `command`: Current command type
- `wait_type`: Current wait type
- `wait_time`: Current wait duration
- `ProcessType`: User or System process

### Blocking Chain Result Set
- `BlockingChain`: Visual representation of blocking hierarchy
- `BlockingLevel`: Depth in blocking chain

## Performance Considerations

- The procedure excludes system processes (session_id ≤ 50)
- The current session running the procedure is excluded
- Only active or running sessions are included
- Results are ordered to show blocking sessions first

## Best Practices

1. Use during performance troubleshooting sessions
2. Monitor resource-intensive queries
3. Identify blocking chains quickly
4. Analyze wait statistics and resource usage patterns
5. Review execution plans for problematic queries

## Limitations

- Only captures active sessions and requests
- System processes are excluded
- Query text and plans may be unavailable for encrypted procedures
- Resource usage metrics are cumulative for the session

## Security Considerations

The user executing this procedure needs appropriate permissions to access system DMVs and DMFs, including:
- VIEW SERVER STATE
- VIEW DATABASE STATE

## Version Compatibility

Compatible with SQL Server 2016 and later versions due to the use of:
- sys.dm_exec_sessions
- sys.dm_exec_requests
- sys.dm_exec_sql_text
- sys.dm_exec_query_plan
