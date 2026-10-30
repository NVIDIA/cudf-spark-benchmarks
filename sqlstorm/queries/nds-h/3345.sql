
WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.total_avail_qty, 
           s.avg_supply_cost, 
           RANK() OVER (PARTITION BY s.s_name ORDER BY s.total_avail_qty DESC) AS rank_by_avail_qty
    FROM SupplierStats s
)
SELECT cs.c_name, 
       cs.total_spent, 
       CASE 
           WHEN cs.order_count IS NULL THEN 'No Orders'
           ELSE CAST(cs.order_count AS VARCHAR(255))
       END AS order_status,
       rs.s_name AS top_supplier,
       rs.avg_supply_cost
FROM CustomerOrderStats cs
LEFT JOIN RankedSuppliers rs ON cs.total_spent = (
    SELECT MAX(total_avail_qty)
    FROM RankedSuppliers
)
WHERE cs.total_spent IS NOT NULL
UNION ALL
SELECT 'Unknown Customer' AS c_name, 
       0 AS total_spent, 
       'No Orders' AS order_status, 
       r.s_name AS top_supplier,
       r.avg_supply_cost
FROM RankedSuppliers r
WHERE NOT EXISTS (
    SELECT 1 
    FROM CustomerOrderStats cs 
    WHERE cs.total_spent IS NOT NULL
) 
ORDER BY total_spent DESC, c_name;
