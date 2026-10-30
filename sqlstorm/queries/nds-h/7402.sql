WITH NationStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        n.n_name
),
TopRegions AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ns.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        NationStats ns ON ns.nation_name = n.n_name
    GROUP BY 
        r.r_name
)
SELECT 
    tr.region_name,
    tr.region_revenue,
    ROW_NUMBER() OVER (ORDER BY tr.region_revenue DESC) AS revenue_rank
FROM 
    TopRegions tr
WHERE 
    tr.region_revenue > 100000
ORDER BY 
    tr.region_revenue DESC
LIMIT 10;
