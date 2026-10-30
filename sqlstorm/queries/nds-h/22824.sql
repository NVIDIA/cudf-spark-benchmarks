WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 30
),
SupplierCost AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT p.p_name,
       COALESCE(s.s_name, 'UNKNOWN') AS supplier_name,
       COALESCE(r.total_cost, 0) AS total_cost,
       RANK() OVER (ORDER BY COALESCE(r.total_cost, 0) DESC) AS cost_rank
FROM RankedParts p
LEFT JOIN SupplierCost r ON p.p_partkey = r.ps_partkey
LEFT JOIN HighValueSuppliers s ON r.ps_suppkey = s.s_suppkey
WHERE (p.price_rank < 6 AND s.s_suppkey IS NOT NULL)
   OR (s.s_suppkey IS NULL AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2))
ORDER BY cost_rank ASC;
