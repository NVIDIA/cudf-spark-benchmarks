WITH  order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
ranked_orders AS (
    SELECT 
        os.o_orderkey,
        os.total_items,
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        order_summary os
),
supplier_region AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.total_items,
    ro.total_revenue,
    sr.supplier_nation,
    sr.supplier_region,
    COALESCE(sr.total_supply_value, 0) AS supplier_value,
    CASE 
        WHEN ro.total_revenue > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    ranked_orders ro
FULL OUTER JOIN 
    supplier_region sr ON ro.o_orderkey = sr.s_suppkey
WHERE 
    (ro.total_items IS NOT NULL OR sr.total_supply_value IS NOT NULL)
ORDER BY 
    ro.total_revenue DESC NULLS LAST, 
    sr.supplier_region;