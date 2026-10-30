WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.avg_supplycost
    FROM RankedSuppliers s
    WHERE s.avg_supplycost < (SELECT AVG(avg_supplycost) FROM RankedSuppliers)
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
),
SupplierOrderStats AS (
    SELECT hs.s_suppkey, hs.s_name, os.o_orderkey, os.total_revenue
    FROM HighValueSuppliers hs
    JOIN lineitem l ON hs.s_suppkey = l.l_suppkey
    JOIN OrderStats os ON l.l_orderkey = os.o_orderkey
)
SELECT s.s_name, COUNT(DISTINCT so.o_orderkey) AS order_count, SUM(so.total_revenue) AS total_revenue
FROM SupplierOrderStats so
JOIN HighValueSuppliers s ON so.s_suppkey = s.s_suppkey
GROUP BY s.s_name
ORDER BY total_revenue DESC
LIMIT 10;