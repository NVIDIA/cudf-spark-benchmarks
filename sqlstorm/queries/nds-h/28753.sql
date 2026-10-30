WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           p_mfgr, 
           p_size, 
           p_retailprice, 
           p_comment
    FROM part
    WHERE p_size > 20 AND 
          (p_comment LIKE '%green%' OR p_comment LIKE '%metallic%')
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal,
           SUBSTRING(s.s_address, 1, 20) AS short_address
    FROM supplier s
    WHERE s.s_acctbal > 5000 
),
CustomerPurchase AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT fp.p_name, 
       fp.p_retailprice, 
       CONCAT(sd.s_name, ' (', sd.short_address, ')') AS supplier_info, 
       cp.c_name AS customer_name, 
       cp.total_orders, 
       cp.total_spent
FROM FilteredParts fp
JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN CustomerPurchase cp ON cp.total_orders > 0
WHERE cp.total_spent > 10000
ORDER BY fp.p_retailprice DESC, cp.total_spent DESC
LIMIT 50;
