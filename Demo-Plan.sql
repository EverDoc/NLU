set statistics profile off
set statistics time on
set statistics io on

-- NOTE: the demo database AdventureWorks, go to http://msftdbprodsamples.codeplex.com/ to get it for your SQL Server platform (2008/2012/2014)
--       then restore the database on your SQL Server instance

-- if there is no index on CarrierTrackingNumber, the following query will be running slowly - if there are millions of rows in SalesOrderDetail.
select * 
from [Sales].[SalesOrderDetail]
where CarrierTrackingNumber like '365D%'
go

create nonclustered index IX_SalesOrderDetail_CarrierTrackingNumber on [Sales].[SalesOrderDetail] (CarrierTrackingNumber)
-- drop index [Sales].[SalesOrderDetail].IX_SalesOrderDetail_CarrierTrackingNumber

-- This will not use the created index efficiently, it will use SCAN instead of SEEK
select * 
from [Sales].[SalesOrderDetail]
where CarrierTrackingNumber like '%365D-4C9A-BE'

-- This is another sample to use INDEX SEEK on nonclustered index, then do LOOKUP on clustered index
select  o.SalesOrderID, o.OrderDate, o.DueDate, o.ShipDate, o.Status, o.CustomerID, o.SalesPersonID
from Sales.SalesOrderHeader o
join Sales.Customer c on o.CustomerID = c.CustomerID
where c.AccountNumber = 'AW00029672'

-- What is Algebrizer doing.
SELECT  MakeFlag,SUM(ListPrice)
FROM Production.Product
GROUP BY ProductNumber

-- Parameter Sniffing
SELECT SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail
WHERE ProductID = 897;

SELECT SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail
WHERE ProductID = 945;

SELECT SalesOrderDetailID, OrderQty
FROM Sales.SalesOrderDetail
WHERE ProductID = 870;
go

-- Get Cached Stored Procedure Plan
SELECT TOP (20) object_name(s.object_id, s.database_id) as name, db_name(s.database_id) as db, cached_time, last_execution_time, 
s.execution_count,
-- ISNULL (s.execution_count / DATEDIFF (minute, s.cached_time, GETDATE ()), 0) AS [Calls/minute], 
s.total_elapsed_time / s.execution_count AS [avg_elapsed_time], s.total_worker_time/s.execution_count as avg_worker_time,
s.total_logical_reads / s.execution_count AS [avg_logical_reads], s.total_elapsed_time, s.total_worker_time, s.total_logical_reads
,p.query_plan
FROM sys.dm_exec_procedure_stats AS s with (nolock)
cross apply sys.dm_exec_query_plan (s.plan_handle) as p
order by s.total_worker_time desc

-- Get Cached Query Plan
SELECT top 10 cast(getdate() as smalldatetime) as collection_time, qs.creation_time, qs.last_execution_time, qs.execution_count,
     --ISNULL (qs.execution_count / DATEDIFF (minute, qs.creation_time, GETDATE ()), 0) AS [Calls/minute],
     left(SUBSTRING(qt.text,qs.statement_start_offset/2 +1, (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                                                             ELSE qs.statement_end_offset
                                                             END - qs.statement_start_offset)/2), 500) AS query_text,
     db_name(qt.dbid) as db, qs.total_worker_time, qs.total_worker_time/qs.execution_count as avg_worker_time,     
     qs.total_elapsed_time,   qs.total_elapsed_time/qs.execution_count AS avg_elapsed_time,
     qs.total_physical_reads, qs.total_physical_reads/qs.execution_count as avg_physical_reads,
     qs.total_logical_reads,  qs.total_logical_reads/qs.execution_count as avg_logical_reads,
     qs.total_logical_writes, qs.total_logical_writes/qs.execution_count avg_logical_writes,  qp.query_plan, qt.text
FROM sys.dm_exec_query_stats AS qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
ORDER BY   qs.total_worker_time desc
GO

DBCC FREEPROCCACHE
go

-- If you are interested in how SQL Server creates execution plan based on STATISTCS information,
-- try to use DBCC SHOW_STATISTICS command to check the internal of an statistics object.
DBCC SHOW_STATISTICS('Sales.SalesOrderHeader', 'PK_SalesOrderHeader_SalesOrderID')
DBCC SHOW_STATISTICS('Sales.SalesOrderDetail', 'PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID')

select  count(*)*1.0/count(distinct SalesOrderID), 1.0/count(distinct SalesOrderID) from Sales.SalesOrderDetail

declare @OrderID int = 43899

select SalesOrderID, SalesOrderDetailID from Sales.SalesOrderDetail where SalesOrderID = @OrderID option (recompile)

select * from Sales.SalesOrderHeader order by SalesOrderID
