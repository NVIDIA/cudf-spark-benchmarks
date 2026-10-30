
WITH RankedParts AS (
    SELECT p_partkey, 
           p_name, 
           p_size, 
           p_retailprice,
           RANK() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS price_rank
    FROM part
),
SupplierStats AS (
    SELECT s_nationkey,
           SUM(s_acctbal) AS total_supplier_balance,
           COUNT(DISTINCT s_suppkey) AS supplier_count
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    GROUP BY s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 2 AND SUM(o.o_totalprice) BETWEEN 1000 AND 10000
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey,
           p.p_name,
           s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available_qty
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey, p.p_name, s.s_suppkey, s.s_name
)
SELECT r.p_partkey,
       r.p_name,
       COALESCE(ss.total_supplier_balance, 0) AS total_supplier_balance,
       COALESCE(ss.supplier_count, 0) AS supplier_count,
       COALESCE(po.total_spent, 0) AS total_spent,
       (SELECT COUNT(*) 
        FROM lineitem l 
        WHERE l.l_partkey = r.p_partkey AND l.l_discount = 0.05) AS no_discount_sales,
       CASE 
           WHEN r.price_rank <= 3 THEN 'Top 3'
           ELSE 'Other'
       END AS price_category
FROM RankedParts r
LEFT JOIN SupplierStats ss ON r.p_partkey = ss.s_nationkey
LEFT JOIN CustomerOrders po ON po.c_custkey = ss.s_nationkey
WHERE EXISTS (SELECT 1 
              FROM PartSupplierInfo psi 
              WHERE psi.ps_partkey = r.p_partkey AND psi.total_available_qty > 50)
ORDER BY r.p_partkey
LIMIT 50;
