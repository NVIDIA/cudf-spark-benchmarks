WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStatistics AS (
    SELECT l.l_suppkey, AVG(l.l_extendedprice) AS avg_extended_price,
           SUM(l.l_quantity) AS total_quantity,
           COUNT(*) AS line_items_count
    FROM lineitem l
    GROUP BY l.l_suppkey
)
SELECT 
    co.c_name AS customer_name, 
    COALESCE(sp.s_name, 'No supplier') AS supplier_name, 
    co.total_spent, 
    sp.part_count, 
    lis.avg_extended_price, 
    lis.total_quantity,
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Spender'
        WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM CustomerOrders co
LEFT JOIN SupplierParts sp ON co.c_custkey = sp.s_suppkey
LEFT JOIN LineItemStatistics lis ON sp.s_suppkey = lis.l_suppkey
WHERE (sp.part_count IS NOT NULL OR co.total_spent > 5000)
  AND (sp.s_name IS NOT NULL OR co.total_spent IS NULL)
ORDER BY co.total_spent DESC, lis.total_quantity ASC;
