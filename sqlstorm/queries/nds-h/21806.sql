WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
CompositeOrders AS (
    SELECT 
        lo.l_orderkey,
        COUNT(DISTINCT lo.l_partkey) AS distinct_parts,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS net_revenue
    FROM 
        lineitem lo
    WHERE 
        lo.l_quantity > 1 AND lo.l_returnflag = 'N'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.o_orderkey,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        WHEN r.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_state,
    COALESCE(co.distinct_parts, 0) AS total_parts,
    fs.total_supply_cost / NULLIF(SUM(COALESCE(co.net_revenue, 0)), 0) AS cost_to_revenue_ratio
FROM 
    RankedOrders r
LEFT JOIN 
    CompositeOrders co ON r.o_orderkey = co.l_orderkey
LEFT JOIN 
    FilteredSuppliers fs ON fs.total_supply_cost > 1000
WHERE 
    r.price_rank = 1 
    AND (r.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01' OR r.o_orderdate IS NULL)
GROUP BY 
    r.o_orderkey, r.o_orderstatus, co.distinct_parts, fs.total_supply_cost
HAVING 
    COUNT(r.o_orderkey) > 5
ORDER BY 
    cost_to_revenue_ratio DESC NULLS LAST;