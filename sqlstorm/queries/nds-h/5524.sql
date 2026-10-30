WITH supplier_aggregate AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
customer_order_summary AS (
    SELECT 
        c.c_nationkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name, 
        COALESCE(SUM(s.total_cost), 0) AS total_supplier_cost, 
        COALESCE(SUM(cos.total_orders), 0) AS total_orders,
        COALESCE(SUM(cos.total_revenue), 0) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier_aggregate s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer_order_summary cos ON n.n_nationkey = cos.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name, 
    r.total_supplier_cost, 
    r.total_orders, 
    r.total_revenue,
    (CASE WHEN r.total_orders > 0 THEN (r.total_revenue / r.total_orders) ELSE 0 END) AS avg_order_value
FROM 
    region_summary r
ORDER BY 
    r.total_supplier_cost DESC, 
    r.total_revenue DESC;
