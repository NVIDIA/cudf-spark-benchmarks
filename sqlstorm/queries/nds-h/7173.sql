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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
RankedRevenue AS (
    SELECT 
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueByNation
)
SELECT 
    rr.nation,
    rr.total_revenue
FROM 
    RankedRevenue rr
WHERE 
    rr.revenue_rank <= 10
ORDER BY 
    rr.total_revenue DESC;