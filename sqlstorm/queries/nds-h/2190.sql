WITH RegionalSales AS (
    SELECT 
        r.r_name, 
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
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        r_name, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionalSales
)
SELECT 
    r.r_name,
    COALESCE(tr.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN tr.revenue_rank <= 5 THEN 'Top 5 Region'
        ELSE 'Other Region'
    END AS region_category
FROM 
    region r
LEFT JOIN 
    TopRegions tr ON r.r_name = tr.r_name
ORDER BY 
    r.r_name;