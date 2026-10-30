
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) 
                          FROM supplier s2 
                          WHERE s2.s_nationkey = s.s_nationkey)
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_qty, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT rs.s_name, rs.nation_name, ro.c_name, ro.total_amount, sp.total_qty, sp.total_cost
FROM RankedSuppliers rs
JOIN RecentOrders ro ON rs.s_suppkey = ro.o_orderkey
JOIN SupplierPerformance sp ON rs.s_suppkey = sp.ps_suppkey
WHERE rs.rnk <= 3
ORDER BY rs.nation_name, rs.s_acctbal DESC, ro.total_amount DESC;
