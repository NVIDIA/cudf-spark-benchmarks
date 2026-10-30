
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (SELECT AVG(ps2.ps_supplycost) 
         FROM partsupp ps2 
         WHERE ps2.ps_partkey = ps.ps_partkey) AS avg_supplycost
    FROM 
        partsupp ps
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        rt.r_name
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON l.l_orderkey = ro.o_orderkey
    LEFT JOIN 
        supplier s ON s.s_suppkey = l.l_suppkey
    LEFT JOIN 
        nation n ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        region rt ON rt.r_regionkey = n.n_regionkey
    WHERE 
        ro.order_rank = 1 AND ro.o_totalprice > 1000
),
FinalResult AS (
    SELECT 
        p.p_name,
        sp.ps_availqty,
        COALESCE(sp.ps_supplycost - sp.avg_supplycost, 0) AS supply_cost_variance,
        hvo.o_orderdate
    FROM 
        part p
    JOIN 
        SupplierParts sp ON sp.ps_partkey = p.p_partkey
    FULL OUTER JOIN 
        HighValueOrders hvo ON hvo.o_orderkey = sp.ps_suppkey
    WHERE 
        (p.p_size IS NULL OR p.p_size > 10)
        AND (p.p_comment LIKE '%fragile%' OR hvo.r_name IS NULL)
)
SELECT 
    f.p_name,
    COUNT(f.o_orderdate) AS order_count,
    SUM(f.supply_cost_variance) AS total_supply_cost_variance
FROM 
    FinalResult f
GROUP BY 
    f.p_name
HAVING 
    SUM(f.supply_cost_variance) > 0
ORDER BY 
    total_supply_cost_variance DESC
LIMIT 10;
