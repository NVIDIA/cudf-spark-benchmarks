WITH RevenueByNation AS (
    SELECT 
        n.n_name AS nation,
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
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueByNation
)
SELECT 
    t.nation,
    t.total_revenue,
    r.r_name AS region
FROM 
    TopNations t
JOIN 
    nation n ON t.nation = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.revenue_rank <= 5
ORDER BY 
    t.total_revenue DESC;
