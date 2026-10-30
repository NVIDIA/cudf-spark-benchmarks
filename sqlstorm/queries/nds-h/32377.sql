WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent, 
           DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, p.p_name, s.s_name,
           ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS row_num
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT tc.c_name, 
       SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue, 
       COUNT(DISTINCT lp.l_orderkey) AS order_count,
       MAX(SP.p_name) AS most_expensive_part,
       CASE 
           WHEN SUM(lp.l_extendedprice * (1 - lp.l_discount)) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Found'
       END AS revenue_status
FROM TopCustomers tc
JOIN orders o ON tc.c_custkey = o.o_custkey
JOIN lineitem lp ON o.o_orderkey = lp.l_orderkey
LEFT JOIN SupplierParts SP ON lp.l_partkey = SP.ps_partkey AND SP.row_num = 1
GROUP BY tc.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 1
ORDER BY revenue DESC
LIMIT 10;
