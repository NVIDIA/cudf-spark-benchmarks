WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_order_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT ss.s_suppkey,
           ss.s_name,
           ss.total_supply_cost,
           ss.distinct_parts,
           ROW_NUMBER() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM SupplierStats ss
    WHERE ss.total_supply_cost > (
        SELECT AVG(total_supply_cost)
        FROM SupplierStats
    )
),
CustomerDetail AS (
    SELECT co.c_custkey,
           co.c_name,
           COALESCE(co.total_order_value, 0) AS total_order_value,
           COALESCE(co.order_count, 0) AS order_count,
           hvs.s_name AS supplier_name,
           hvs.total_supply_cost
    FROM CustomerOrders co
    LEFT JOIN HighValueSuppliers hvs ON co.c_custkey = hvs.s_suppkey
)
SELECT cd.c_custkey,
       cd.c_name,
       cd.total_order_value,
       cd.order_count,
       cd.supplier_name,
       cd.total_supply_cost,
       CASE 
           WHEN cd.total_order_value >= 10000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_type
FROM CustomerDetail cd
ORDER BY cd.total_order_value DESC, cd.order_count DESC;
