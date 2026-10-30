WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_name LIKE '%special%'
),
CustomerSummary AS (
    SELECT c.c_nationkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT r.r_name, 
       COUNT(DISTINCT rp.p_partkey) AS total_special_parts, 
       cs.total_orders, 
       cs.total_spent
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
JOIN CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
GROUP BY r.r_name, cs.total_orders, cs.total_spent
ORDER BY r.r_name;
