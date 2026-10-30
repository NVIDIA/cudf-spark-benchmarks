WITH RecursivePart AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice * 1.1 AS inflated_price,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price
    FROM part p
), 
CheapestSupplier AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           MIN(ps.ps_supplycost) AS min_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 0
), 
SupplierRank AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT rp.p_name,
       rp.inflated_price,
       cs.min_supplycost,
       co.total_spent,
       sr.supply_rank
FROM RecursivePart rp
LEFT JOIN CheapestSupplier cs ON rp.p_partkey = cs.ps_partkey
LEFT JOIN CustomerOrders co ON cs.ps_suppkey = co.c_custkey
FULL OUTER JOIN SupplierRank sr ON cs.ps_suppkey = sr.s_suppkey
WHERE (rp.rank_price <= 5 OR sr.supply_rank IS NULL)
  AND (co.total_spent IS NULL OR co.total_spent > 1000)
  AND NOT EXISTS (SELECT 1 
                  FROM lineitem l 
                  WHERE l.l_partkey = rp.p_partkey 
                  AND l.l_discount > 0.15)
ORDER BY rp.inflated_price DESC NULLS LAST, sr.supply_rank ASC;
