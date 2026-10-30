WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, SUM(rs.total_cost) AS nation_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ns.n_name, ns.nation_cost, od.order_total, COUNT(DISTINCT od.o_orderkey) AS total_orders
FROM NationSummary ns
JOIN OrderDetails od ON ns.n_nationkey = (
    SELECT c.c_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderkey IN (SELECT o_orderkey FROM orders)
    LIMIT 1 
)
GROUP BY ns.n_name, ns.nation_cost, od.order_total
ORDER BY ns.nation_cost DESC, od.order_total DESC
LIMIT 10;