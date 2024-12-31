CREATE OR ALTER PROCEDURE sp_GetActiveProcesses
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get active processes with detailed information
    SELECT 
        s.session_id,
        DB_NAME(r.database_id) AS DatabaseName,
        s.login_name AS LoginName,
        s.host_name AS HostName,
        s.program_name AS ProgramName,
        CASE s.transaction_isolation_level 
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'ReadUncommitted'
            WHEN 2 THEN 'ReadCommitted'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
        END AS IsolationLevel,
        s.login_time AS LoginTime,
        s.last_request_start_time AS LastRequestStartTime,
        CAST(r.total_elapsed_time / 1000.0 / 60.0 AS DECIMAL(18,2)) AS ElapsedMinutes,
        CAST(r.cpu_time / 1000.0 / 60.0 AS DECIMAL(18,2)) AS CPUMinutes,
        CAST(r.logical_reads / 128.0 / 1024.0 AS DECIMAL(18,2)) AS LogicalReadGB,
        CAST(r.reads / 128.0 / 1024.0 AS DECIMAL(18,2)) AS PhysicalReadGB,
        CAST(r.writes / 128.0 / 1024.0 AS DECIMAL(18,2)) AS WritesGB,
        r.row_count AS RowCount,
        r.granted_query_memory * 8 / 1024 AS GrantedMemoryMB,
        CASE r.blocking_session_id
            WHEN 0 THEN ''
            ELSE CAST(r.blocking_session_id AS VARCHAR)
        END AS BlockingSessionID,
        SUBSTRING(
            qt.text, 
            r.statement_start_offset/2 + 1,
            (CASE WHEN r.statement_end_offset = -1
                THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                ELSE r.statement_end_offset
            END - r.statement_start_offset)/2
        ) AS CurrentStatement,
        qt.text AS FullQueryText,
        qp.query_plan AS QueryPlan,
        r.status,
        r.command,
        r.wait_type,
        r.wait_time,
        r.last_wait_type,
        s.deadlock_priority,
        s.lock_timeout,
        CASE s.is_user_process
            WHEN 1 THEN 'User Process'
            ELSE 'System Process'
        END AS ProcessType
    FROM sys.dm_exec_sessions s
    LEFT JOIN sys.dm_exec_requests r 
        ON s.session_id = r.session_id
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) qt
    OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) qp
    WHERE s.session_id > 50  -- Exclude system processes
        AND s.session_id <> @@SPID  -- Exclude current session
        AND (
            r.session_id IS NOT NULL  -- Session is running a query
            OR s.status <> 'sleeping' -- Session is active but not running a query
        )
    ORDER BY 
        CASE 
            WHEN r.blocking_session_id > 0 THEN 0  -- Show blocking sessions first
            ELSE 1
        END,
        r.cpu_time DESC,
        r.total_elapsed_time DESC;

    -- Get blocking chain if exists
    IF EXISTS (SELECT 1 FROM sys.dm_exec_requests WHERE blocking_session_id > 0)
    BEGIN
        PRINT 'Blocking Chain:';
        
        ;WITH BlockingChain AS (
            SELECT 
                w.session_id,
                w.blocking_session_id,
                CAST(w.session_id AS VARCHAR(10)) AS chain,
                1 AS level
            FROM sys.dm_exec_requests w
            WHERE w.blocking_session_id = 0
                AND EXISTS (SELECT * FROM sys.dm_exec_requests w2 WHERE w2.blocking_session_id = w.session_id)
            
            UNION ALL
            
            SELECT 
                w.session_id,
                w.blocking_session_id,
                CAST(b.chain + ' -> ' + CAST(w.session_id AS VARCHAR(10)) AS VARCHAR(1000)),
                b.level + 1
            FROM sys.dm_exec_requests w
            INNER JOIN BlockingChain b ON b.session_id = w.blocking_session_id
        )
        SELECT 
            chain AS BlockingChain,
            level AS BlockingLevel
        FROM BlockingChain
        ORDER BY level;
    END
END;
GO 