
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 5000
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerTotal AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS customer_revenue
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ct.c_name, 
       COALESCE(ct.customer_revenue, 0) AS total_customer_revenue,
       sd.total_supply_cost
FROM CustomerTotal ct
LEFT JOIN SupplierDetails sd ON ct.c_custkey = sd.s_suppkey
WHERE sd.total_supply_cost IS NOT NULL OR COALESCE(ct.customer_revenue, 0) = 0
ORDER BY total_customer_revenue DESC, sd.total_supply_cost ASC
LIMIT 100;
