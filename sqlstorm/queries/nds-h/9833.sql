WITH RankedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    ORDER BY total_cost DESC
    LIMIT 5
),
HighRevenueOrders AS (
    SELECT ro.o_orderkey, ro.total_revenue, o.o_orderstatus, o.o_orderdate
    FROM RankedOrders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    WHERE ro.total_revenue > 10000
)
SELECT o.o_orderkey, o.total_revenue, s.s_name, r.r_name, n.n_name
FROM HighRevenueOrders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE s.s_suppkey IN (SELECT ts.s_suppkey FROM TopSuppliers ts)
ORDER BY o.total_revenue DESC, o.o_orderkey ASC;