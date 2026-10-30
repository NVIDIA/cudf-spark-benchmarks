WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    ROUND(COALESCE(ss.total_supply_cost, 0) / NULLIF(COALESCE(os.total_revenue, 0), 0), 2) AS cost_to_revenue_ratio
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_summary ss ON n.n_nationkey = ss.s_suppkey  
FULL OUTER JOIN 
    order_summary os ON n.n_nationkey = os.o_orderkey
WHERE 
    r.r_name LIKE '%South%'
ORDER BY 
    cost_to_revenue_ratio DESC, total_revenue DESC
LIMIT 10;