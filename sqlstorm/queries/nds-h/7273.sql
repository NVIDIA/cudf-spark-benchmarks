WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT *, RANK() OVER (PARTITION BY nation_name ORDER BY total_cost DESC) AS rank
    FROM SupplierDetails
),
OrdersSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_custkey
)
SELECT ts.nation_name, ts.s_name, ts.total_cost, os.total_orders, os.total_revenue
FROM TopSuppliers ts
JOIN OrdersSummary os ON ts.s_nationkey = os.o_custkey
WHERE ts.rank <= 5 AND os.total_orders > 10
ORDER BY ts.nation_name, ts.total_cost DESC;
