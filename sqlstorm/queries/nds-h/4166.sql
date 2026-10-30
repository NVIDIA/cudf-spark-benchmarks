WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(p.ps_partkey) AS part_count,
        SUM(p.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), 
OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(oi.total_revenue) AS customer_total_spent,
        COUNT(oi.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN OrderInfo oi ON c.c_custkey = oi.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    s.s_suppkey, 
    s.s_name, 
    s.part_count, 
    s.total_supply_cost, 
    cs.order_count, 
    COALESCE(cs.customer_total_spent, 0) AS customer_total_spent,
    CASE 
        WHEN cs.customer_total_spent IS NULL THEN 'No Orders'
        WHEN cs.customer_total_spent < 1000 THEN 'Low Spending'
        WHEN cs.customer_total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spending'
        ELSE 'High Spending'
    END AS spending_category
FROM SupplierInfo s
FULL OUTER JOIN CustomerSpending cs ON s.part_count = cs.order_count
ORDER BY s.s_suppkey, cs.customer_total_spent DESC;
