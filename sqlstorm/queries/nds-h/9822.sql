WITH Revenue AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        ps.ps_partkey
), RankedRevenue AS (
    SELECT 
        p.p_name,
        r.total_revenue,
        RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        Revenue r ON p.p_partkey = r.ps_partkey
)
SELECT 
    r.p_name,
    r.total_revenue,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top 10'
        WHEN r.revenue_rank <= 30 THEN 'Top 30'
        ELSE 'Others'
    END AS revenue_category
FROM 
    RankedRevenue r
WHERE 
    r.total_revenue > 10000
ORDER BY 
    r.total_revenue DESC;