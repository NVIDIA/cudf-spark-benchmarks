
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 DAYS'
),
LateShipments AS (
    SELECT l.l_orderkey, COUNT(*) AS late_count
    FROM lineitem l
    WHERE l.l_returnflag = 'R' AND l.l_shipdate > l.l_commitdate
    GROUP BY l.l_orderkey
)
SELECT r.r_name, SUM(oo.o_totalprice) AS total_revenue, COUNT(DISTINCT so.s_suppkey) AS supplier_count,
       SUM(COALESCE(ls.late_count, 0)) AS total_late_shipments
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN RecentOrders oo ON oo.o_custkey = c.c_custkey
JOIN TopSuppliers so ON so.s_suppkey IN (SELECT ps.ps_suppkey
                                           FROM partsupp ps
                                           JOIN lineitem li ON li.l_partkey = ps.ps_partkey
                                           WHERE li.l_orderkey = oo.o_orderkey)
LEFT JOIN LateShipments ls ON ls.l_orderkey = oo.o_orderkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;
