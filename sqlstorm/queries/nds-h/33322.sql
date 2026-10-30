WITH  PurchaseHierarchy AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, c.c_name
), HighValueCustomers AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY c.c_name
    HAVING SUM(l.l_extendedprice) > 1000
)
SELECT 
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    COALESCE(hvc.total_spent, 0) AS high_value_customer_spending,
    CASE 
        WHEN SUM(ps.ps_supplycost * ps.ps_availqty) > COALESCE(hvc.total_spent, 0) THEN 'High Cost'
        ELSE 'Low Cost'
    END AS cost_category
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN HighValueCustomers hvc ON p.p_brand = hvc.c_name
GROUP BY p.p_name, hvc.total_spent
ORDER BY total_cost DESC
LIMIT 10;