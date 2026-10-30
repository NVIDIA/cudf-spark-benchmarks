
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_name,
        s.s_name,
        l.l_discount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '12 months' 
        AND l.l_discount IS NULL
),
SupplierRanked AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
RegionDetails AS (
    SELECT 
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name AS customer_name,
    ro.s_name AS supplier_name,
    ro.order_rank,
    sr.unique_parts,
    sr.avg_supplycost,
    rd.r_name AS region_name,
    rd.nation_count
FROM RankedOrders ro
FULL OUTER JOIN SupplierRanked sr ON ro.s_name = sr.s_name
LEFT JOIN RegionDetails rd ON ro.c_name IN (SELECT c.c_name FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IS NOT NULL))
WHERE 
    (ro.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) OR ro.order_rank = 1)
    AND (sr.avg_supplycost IS NOT NULL OR sr.unique_parts > 0)
ORDER BY 
    ro.o_orderdate DESC,
    ro.o_totalprice ASC
LIMIT 100;
