WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT *,
           RANK() OVER (PARTITION BY CASE 
                                        WHEN total_cost > 10000 THEN 'High'
                                        WHEN total_cost BETWEEN 5000 AND 10000 THEN 'Medium'
                                        ELSE 'Low'
                                   END 
                       ORDER BY total_cost DESC) AS cost_rank
    FROM SupplierCosts
),
ActiveCustomers AS (
    SELECT co.c_custkey, co.c_name, co.order_count, co.total_spent,
           ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM CustomerOrders co
    WHERE co.order_count > 0
)
SELECT ac.c_name, ac.total_spent, ss.s_name, ss.total_cost
FROM ActiveCustomers ac
LEFT JOIN RankedSuppliers ss ON ac.customer_rank = ss.cost_rank
WHERE ac.total_spent > 1000 AND ss.total_cost IS NOT NULL
UNION
SELECT ac.c_name, ac.total_spent, NULL AS s_name, NULL AS total_cost
FROM ActiveCustomers ac
WHERE ac.total_spent <= 1000
ORDER BY total_spent DESC, c_name ASC;
