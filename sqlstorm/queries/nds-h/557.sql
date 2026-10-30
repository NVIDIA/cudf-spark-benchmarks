WITH revenue_summary AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_nationkey
),
supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey
),
combined_summary AS (
    SELECT 
        r.r_regionkey,
        SUM(rs.total_revenue) AS region_revenue,
        SUM(ss.total_supply_cost) AS region_supply_cost,
        SUM(rs.order_count) AS region_order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        revenue_summary rs ON n.n_nationkey = rs.c_nationkey
    LEFT JOIN 
        supplier_summary ss ON n.n_nationkey = ss.ps_partkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name, 
    cs.region_revenue, 
    cs.region_supply_cost, 
    CASE 
        WHEN cs.region_order_count > 0 THEN cs.region_revenue / cs.region_order_count 
        ELSE NULL 
    END AS avg_revenue_per_order
FROM 
    combined_summary cs
JOIN 
    region r ON cs.r_regionkey = r.r_regionkey
WHERE 
    cs.region_revenue IS NOT NULL
ORDER BY 
    r.r_name ASC, 
    avg_revenue_per_order DESC;