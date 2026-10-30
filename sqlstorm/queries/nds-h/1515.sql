
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierPartDetails AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(l.total_revenue), 0) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPartDetails sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    LineItemSummary l ON sp.ps_partkey = l.l_orderkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.order_rank = 1
GROUP BY 
    r.r_name
HAVING 
    SUM(l.total_revenue) > 0 
    OR COUNT(DISTINCT o.o_orderkey) > 0 
ORDER BY 
    revenue DESC;
