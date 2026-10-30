
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer AS c
    JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.order_count, c.total_spent
    FROM CustomerOrders AS c
    WHERE c.order_count > 5 AND c.total_spent > 5000
),
PartSuppliers AS (
    SELECT ps.ps_partkey, s.s_name AS supplier_name
    FROM partsupp AS ps
    JOIN supplier AS s ON ps.ps_suppkey = s.s_suppkey
)
SELECT t.c_name, t.order_count, t.total_spent, p.p_name, p.p_brand, ps.supplier_name
FROM TopCustomers AS t
JOIN lineitem AS l ON t.c_custkey = l.l_orderkey
JOIN PartSuppliers AS ps ON ps.ps_partkey = l.l_partkey
JOIN part AS p ON p.p_partkey = ps.ps_partkey
WHERE p.p_brand LIKE 'Brand%'
ORDER BY t.total_spent DESC, t.order_count DESC;
