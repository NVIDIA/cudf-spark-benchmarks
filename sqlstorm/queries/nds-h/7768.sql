WITH SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sc.total_cost
    FROM supplier s
    JOIN SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(l.l_orderkey) AS lineitem_count
    FROM lineitem l
    JOIN highValueOrders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT ns.n_name, ts.s_name, od.total_revenue, od.lineitem_count, ns.customer_count
FROM OrderDetails od
JOIN TopSuppliers ts ON od.o_orderkey = ts.s_suppkey
JOIN NationStats ns ON ts.s_suppkey = ns.n_nationkey
WHERE od.total_revenue > 5000
ORDER BY ns.n_name, od.total_revenue DESC;
