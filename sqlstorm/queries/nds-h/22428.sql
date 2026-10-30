WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) as order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) as supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rn.s_name, 'No Suppliers') AS supplier_name,
    COALESCE(hc.c_name, 'No High Value Customers') AS customer_name,
    CASE 
        WHEN ss.supplier_count IS NULL THEN 'No Supply'
        ELSE CAST(ss.supplier_count AS STRING) || ' Suppliers'
    END AS supplier_description,
    CASE 
        WHEN hc.order_count > 0 THEN 'Frequent Buyer'
        ELSE 'One-time Buyer'
    END AS buyer_status,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as part_rank
FROM part p
LEFT JOIN RankedSuppliers rn ON rn.rank = 1 
LEFT JOIN HighValueCustomers hc ON hc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal = (SELECT MAX(c2.c_acctbal) FROM customer c2))
LEFT JOIN SupplierStats ss ON ss.ps_partkey = p.p_partkey
WHERE p.p_size BETWEEN 1 AND 50 
  AND (p.p_retailprice IS NOT NULL OR p.p_comment LIKE '%Special%')
ORDER BY p.p_partkey DESC
LIMIT 10;

