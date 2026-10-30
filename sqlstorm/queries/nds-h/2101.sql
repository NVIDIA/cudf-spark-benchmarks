WITH SupplierSum AS (
    SELECT s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM partsupp 
    JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
    GROUP BY s_nationkey
),
CustomerOrders AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_nationkey
),
RankedSuppliers AS (
    SELECT ss.s_nationkey, ss.total_supply_value,
           ROW_NUMBER() OVER (PARTITION BY ss.s_nationkey ORDER BY ss.total_supply_value DESC) AS rnk
    FROM SupplierSum ss
)
SELECT r.r_name, 
       COALESCE(cs.total_orders, 0) AS total_customer_orders,
       COALESCE(rs.total_supply_value, 0) AS total_supplier_value,
       CASE 
           WHEN COALESCE(cs.total_orders, 0) > 0 THEN 
               ROUND(COALESCE(rs.total_supply_value, 0) / NULLIF(cs.total_orders, 0), 2)
           ELSE 
               0
       END AS avg_supply_per_order
FROM region r
LEFT JOIN CustomerOrders cs ON r.r_regionkey = cs.c_nationkey
LEFT JOIN RankedSuppliers rs ON r.r_regionkey = rs.s_nationkey AND rs.rnk = 1
WHERE r.r_name LIKE 'A%' 
  AND COALESCE(rs.total_supply_value, 0) > 10000
ORDER BY r.r_name;
