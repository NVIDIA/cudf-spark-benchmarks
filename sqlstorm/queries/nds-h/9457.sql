WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS customer_revenue
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.s_name, cs.total_available, cs.total_cost, cr.c_name, cr.customer_revenue
FROM SupplierStats cs
JOIN CustomerRevenue cr ON cr.customer_revenue > 10000
WHERE cs.total_available > 5000
ORDER BY cr.customer_revenue DESC, cs.total_cost ASC
LIMIT 10;
