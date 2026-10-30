
WITH RevenueByNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        n.n_name
),
RankedRevenue AS (
    SELECT 
        nation_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueByNation
)
SELECT 
    r.nation_name AS nation,
    r.total_revenue,
    CASE 
        WHEN r.revenue_rank = 1 THEN 'Highest Revenue'
        WHEN r.revenue_rank <= 5 THEN 'Top 5 Revenues'
        ELSE 'Other Nations'
    END AS revenue_category
FROM 
    RankedRevenue r
ORDER BY 
    r.total_revenue DESC;
