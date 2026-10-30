WITH SupplierPartCount AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sp.part_count
    FROM SupplierPartCount sp
    INNER JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
    ORDER BY sp.part_count DESC
    LIMIT 5
),
CustomerOrderStatistics AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    t.s_name AS supplier_name,
    t.part_count,
    c.c_name AS customer_name,
    c.order_count,
    c.total_spent,
    ROW_NUMBER() OVER (PARTITION BY t.s_suppkey ORDER BY c.total_spent DESC) AS customer_rank
FROM TopSuppliers t
CROSS JOIN CustomerOrderStatistics c
WHERE c.total_spent > 1000
ORDER BY t.s_suppkey, c.total_spent DESC;
