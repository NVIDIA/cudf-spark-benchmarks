
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, COALESCE(os.total_revenue, 0) AS total_revenue, COALESCE(os.order_count, 0) AS order_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    LEFT JOIN SupplierDetails cs ON c.c_nationkey = cs.s_nationkey
)
SELECT cd.c_custkey, cd.c_name, cd.nation_name, COALESCE(cd.total_revenue, 0) AS total_revenue, COALESCE(cd.order_count, 0) AS order_count
FROM CustomerDetails cd
WHERE cd.total_revenue > 10000
ORDER BY cd.total_revenue DESC, cd.order_count DESC
LIMIT 100;
