WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container IS NOT NULL)
),
CustomerTotal AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 0
)
SELECT DISTINCT 
       r.r_name AS region_name,
       count(*) FILTER (WHERE lp.l_shipdate < cast('1998-10-01' as date)) AS shipped_items,
       SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS net_revenue,
       (SELECT COUNT(*) FROM CustomerTotal ct WHERE ct.total_spent > 50000) AS high_value_customers,
       COUNT(DISTINCT rnk.p_partkey) AS top_parts_count
FROM RankedParts rnk
LEFT JOIN lineitem lp ON rnk.p_partkey = lp.l_partkey
JOIN partsupp ps ON ps.ps_partkey = rnk.p_partkey
JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rnk.rnk <= 5 AND (lp.l_returnflag IS NULL OR lp.l_returnflag = 'N')
GROUP BY r.r_name
ORDER BY net_revenue DESC, region_name ASC
LIMIT 10;