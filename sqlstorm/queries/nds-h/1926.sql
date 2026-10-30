WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS orders_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT co.*, 
           RANK() OVER (ORDER BY co.total_spent DESC) AS order_rank
    FROM CustomerOrders co
    WHERE co.total_spent IS NOT NULL
),
MaxOrder AS (
    SELECT MAX(total_spent) AS max_total_spent
    FROM RankedOrders
)

SELECT r.r_name, 
       s.s_name, 
       sc.total_cost, 
       ro.orders_count, 
       ro.total_spent,
       CASE 
           WHEN ro.orders_count > 0 THEN 
               ROUND((ro.total_spent / ro.orders_count), 2)
           ELSE 
               NULL 
       END AS avg_order_value,
       COALESCE(rn.max_total_spent, 0) AS max_spent
FROM region r
FULL OUTER JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN RankedOrders ro ON s.s_suppkey = ro.c_custkey
CROSS JOIN MaxOrder rn
WHERE sc.total_cost > 1000 OR ro.total_spent IS NOT NULL
ORDER BY r.r_name, sc.total_cost DESC;
