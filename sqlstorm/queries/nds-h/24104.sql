WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        SUM(CASE WHEN n.n_name IS NULL THEN 1 ELSE 0 END) AS null_nations,
        COUNT(n.n_nationkey) AS total_nations
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    ss.avg_supply_cost,
    ss.max_avail_qty,
    rn.null_nations,
    rn.total_nations
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierSummary ss ON ro.rank_revenue < 10
JOIN 
    RegionNations rn ON rn.total_nations > 5
WHERE 
    ro.total_revenue IS NOT NULL
    AND ss.avg_supply_cost IS NOT NULL
    AND (rn.null_nations > 0 OR rn.null_nations IS NULL)
ORDER BY 
    ro.total_revenue DESC, ss.avg_supply_cost ASC
LIMIT 100;
