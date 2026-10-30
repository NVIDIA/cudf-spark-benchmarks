WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1993-01-01' AND DATE '1994-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, r.total_revenue
    FROM RankedOrders r
    JOIN orders o ON r.o_orderkey = o.o_orderkey
    WHERE r.rank <= 10
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT t.o_orderkey, t.o_orderdate, t.total_revenue, s.s_name, s.avg_supply_cost, n.n_name AS supplier_nation
FROM TopRevenueOrders t
JOIN lineitem l ON t.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
ORDER BY t.total_revenue DESC, s.avg_supply_cost ASC;
