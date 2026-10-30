WITH RecursiveOrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(o_summary.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(s_agg.total_cost), 0) AS total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RecursiveOrderSummary o_summary ON o.o_orderkey = o_summary.o_orderkey
LEFT JOIN 
    SupplierAggregates s_agg ON s_agg.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand NOT LIKE 'Brand#%')
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 AND 
    COALESCE(SUM(o_summary.total_revenue), 0) > 10000
ORDER BY 
    total_supply_cost DESC, 
    total_revenue DESC;
