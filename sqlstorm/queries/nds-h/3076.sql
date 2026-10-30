WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_orderdate >= '1997-01-01'
),

SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)

SELECT 
    ro.o_orderkey,
    ro.o_totalprice,
    ro.c_name,
    ss.s_name AS supplier_name,
    ss.unique_parts,
    ss.total_supply_cost,
    (COALESCE(ss.total_supply_cost, 0) / NULLIF(ro.o_totalprice, 0)) * 100 AS cost_percentage,
    RANK() OVER (ORDER BY ro.o_totalprice DESC) AS order_rank
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierSummary ss ON ps.ps_suppkey = ss.s_suppkey
WHERE 
    ro.rank_order <= 10
    AND (ss.unique_parts IS NULL OR ss.unique_parts > 5)
ORDER BY 
    ro.o_totalprice DESC
LIMIT 20;