
WITH SupplierRevenue AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue
    FROM supplier s
    JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
    ORDER BY sr.total_revenue DESC
    LIMIT 10
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT ts.s_name AS supplier_name, ts.total_revenue, cos.c_name AS customer_name, cos.order_count, cos.total_spent
FROM TopSuppliers ts
JOIN CustomerOrderStats cos ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE ts.total_revenue > 100000
ORDER BY ts.total_revenue DESC, cos.total_spent DESC;
