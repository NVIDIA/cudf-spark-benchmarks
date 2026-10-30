
WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
PartSupplierAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SupplierNation AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    p.p_retailprice * (1 - COALESCE(SUM(li.l_discount), 0)) AS calculated_retail_price,
    s.nation_name,
    oh.order_rank
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN PartSupplierAggregation psa ON p.p_partkey = psa.ps_partkey
LEFT JOIN SupplierNation s ON li.l_suppkey = s.s_suppkey
LEFT JOIN OrderHierarchy oh ON li.l_orderkey = oh.o_orderkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part)
  AND p.p_brand <> 'Brand#45'
  AND (psa.total_available_qty IS NULL OR psa.total_available_qty > 100)
GROUP BY p.p_partkey, p.p_name, s.nation_name, oh.order_rank, p.p_retailprice
HAVING p.p_retailprice * (1 - COALESCE(SUM(li.l_discount), 0)) > 20.00
ORDER BY total_revenue DESC, p.p_partkey
LIMIT 100;
