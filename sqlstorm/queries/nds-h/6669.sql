WITH region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
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
    GROUP BY 
        r.r_name
),
top_regions AS (
    SELECT 
        region_name,
        total_revenue,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        region_sales
)
SELECT 
    tr.region_name,
    tr.total_revenue,
    CASE 
        WHEN tr.revenue_rank = 1 THEN 'Top Region'
        WHEN tr.revenue_rank <= 3 THEN 'Top 3 Region'
        ELSE 'Other Region'
    END AS revenue_category
FROM 
    top_regions tr
WHERE 
    tr.revenue_rank <= 10
ORDER BY 
    tr.revenue_rank;
