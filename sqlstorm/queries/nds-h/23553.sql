
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
RecentOrders AS (
    SELECT o.o_custkey, o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY o.o_custkey, o.o_orderkey, o.o_orderdate
),
SuppliersWithOrders AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_fulfilled,
           SUM(CASE WHEN o.o_orderstatus = 'P' THEN o.o_totalprice ELSE 0 END) AS total_pending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.rnk, s.s_name, s.s_nationkey,
       COALESCE(o.total_sales, 0) AS order_total,
       cs.total_fulfilled, cs.total_pending
FROM RankedSuppliers r
JOIN SuppliersWithOrders s ON r.s_suppkey = s.s_suppkey
LEFT JOIN RecentOrders o ON o.o_custkey = s.s_nationkey
LEFT JOIN CustomerSummary cs ON cs.c_custkey = s.s_nationkey
WHERE r.rnk = 1 OR s.order_count > 2
ORDER BY r.rnk DESC, o.total_sales DESC
LIMIT 10;
