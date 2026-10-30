WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.order_rank <= 5
),
SupplierPartPricing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        s.s_name,
        s.s_nationkey
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    fo.o_orderkey,
    SUM(spp.ps_supplycost) AS total_supply_cost,
    COUNT(DISTINCT spp.p_partkey) AS unique_parts,
    COALESCE(r.r_name, 'Unknown Region') AS supplier_region
FROM FilteredOrders fo
LEFT JOIN lineitem li ON fo.o_orderkey = li.l_orderkey
LEFT JOIN SupplierPartPricing spp ON li.l_partkey = spp.p_partkey
LEFT JOIN nation n ON spp.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE fo.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
GROUP BY fo.o_orderkey, r.r_name
HAVING SUM(spp.ps_supplycost) IS NOT NULL AND COUNT(DISTINCT spp.p_partkey) > 0
ORDER BY fo.o_orderkey;