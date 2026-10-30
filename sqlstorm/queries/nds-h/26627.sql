
WITH SupplierCTE AS (
    SELECT s_name, s_address, s_phone, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE POSITION('INC' IN s_comment) > 0
),
PartSummary AS (
    SELECT p_brand AS part_brand, p_type AS part_type, AVG(p_retailprice) AS avg_price, 
           COUNT(DISTINCT p_partkey) AS part_count
    FROM part
    GROUP BY p_brand, p_type
),
CustomerOrders AS (
    SELECT c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name, c.c_acctbal
)
SELECT s.s_name, s.s_address, s.s_phone, s.s_acctbal, 
       ps.part_brand, ps.part_type, ps.avg_price, 
       co.order_count, co.total_spent
FROM SupplierCTE s
JOIN PartSummary ps ON s.rank = 1
JOIN CustomerOrders co ON s.s_acctbal > co.c_acctbal
WHERE COALESCE(co.order_count, 0) > 5
ORDER BY s.s_acctbal DESC, ps.avg_price ASC;
