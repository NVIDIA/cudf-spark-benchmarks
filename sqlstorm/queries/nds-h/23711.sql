WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE
               WHEN p.p_size IS NULL THEN 'UNDEFINED'
               WHEN p.p_size < 10 THEN 'SMALL'
               WHEN p.p_size BETWEEN 10 AND 20 THEN 'MEDIUM'
               ELSE 'LARGE' 
           END AS part_size_category
    FROM part p
    WHERE p.p_retailprice < (SELECT MAX(p1.p_retailprice) * 0.5 FROM part p1)
)
SELECT COALESCE(FP.part_size_category, 'NOT_AVAILABLE') AS size_category,
       COUNT(DISTINCT FS.s_suppkey) AS unique_suppliers,
       SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
       AVG(CASE WHEN O.o_orderstatus = 'F' THEN O.o_totalprice ELSE NULL END) AS avg_filled_order_price
FROM FilteredParts FP
LEFT OUTER JOIN partsupp PS ON FP.p_partkey = PS.ps_partkey
LEFT OUTER JOIN RankedSuppliers FS ON PS.ps_suppkey = FS.s_suppkey
LEFT OUTER JOIN lineitem L ON PS.ps_partkey = L.l_partkey
LEFT OUTER JOIN orders O ON L.l_orderkey = O.o_orderkey
WHERE O.o_orderdate >= DATE '1996-01-01' 
      AND (O.o_orderstatus = 'F' OR O.o_orderstatus IS NULL)
GROUP BY FP.part_size_category
HAVING SUM(L.l_quantity) IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;