WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
MonthlyOrders AS (
    SELECT 
        EXTRACT(MONTH FROM o.o_orderdate) AS month,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    GROUP BY month
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(ss.total_available_qty, 0) AS available_qty,
    COALESCE(ss.avg_supply_cost, 0) AS avg_cost,
    mh.order_count,
    mh.total_revenue
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN MonthlyOrders mh ON mh.month = EXTRACT(MONTH FROM cast('1998-10-01' as date))
WHERE ss.total_available_qty > 100 
    OR mh.order_count > 50
ORDER BY n.n_name, r.r_name
LIMIT 10;