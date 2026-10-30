WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerSegments AS (
    SELECT c.c_nationkey, c.c_mktsegment, SUM(ro.total_revenue) AS segment_revenue
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_nationkey, c.c_mktsegment
)
SELECT ns.n_name, r.r_name, cs.c_mktsegment, SUM(cs.segment_revenue) AS total_segment_revenue
FROM CustomerSegments cs
JOIN nation ns ON cs.c_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23'))
GROUP BY ns.n_name, r.r_name, cs.c_mktsegment
ORDER BY total_segment_revenue DESC;