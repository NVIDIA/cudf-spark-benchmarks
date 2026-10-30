WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS non_null_acctbal
    FROM supplier s
    WHERE s.s_comment IS NOT NULL
),
SupplierPartInventory AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           pp.p_name
    FROM partsupp ps
    JOIN RankedParts pp ON ps.ps_partkey = pp.p_partkey
    WHERE pp.rn <= 5
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AggregatedInventory AS (
    SELECT s.s_suppkey, 
           SUM(sp.ps_availqty * sp.ps_supplycost) AS total_inventory_value
    FROM FilteredSuppliers s
    JOIN SupplierPartInventory sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT co.c_name, 
       co.total_spent, 
       ai.total_inventory_value, 
       CASE 
           WHEN co.total_spent >= ai.total_inventory_value THEN 'High Value' 
           ELSE 'Low Value' 
       END AS customer_value_category
FROM CustomerOrders co
FULL OUTER JOIN AggregatedInventory ai ON co.c_custkey = ai.s_suppkey
WHERE (co.customer_rank <= 10 OR ai.total_inventory_value IS NULL)
AND (co.total_spent IS NOT NULL OR ai.total_inventory_value IS NOT NULL)
ORDER BY co.total_spent DESC NULLS LAST, ai.total_inventory_value ASC NULLS FIRST
LIMIT 10 OFFSET 5;
