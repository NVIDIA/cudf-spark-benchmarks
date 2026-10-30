WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighestCostSupplier AS (
    SELECT s.s_suppkey, s.s_name, sc.total_cost
    FROM SupplierCost sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 1
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    hcss.s_name,
    ro.total_revenue,
    ro.o_orderdate
FROM HighestCostSupplier hcss
JOIN RecentOrders ro ON hcss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderdate >= DATE '1997-01-01'
    )
)
ORDER BY ro.total_revenue DESC
LIMIT 10;