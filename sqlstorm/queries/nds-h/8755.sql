WITH TotalRevenue AS (
    SELECT 
        SUM(l_extendedprice * (1 - l_discount)) AS revenue,
        n_name AS nation_name
    FROM 
        lineitem 
    JOIN 
        orders ON lineitem.l_orderkey = orders.o_orderkey
    JOIN 
        customer ON orders.o_custkey = customer.c_custkey
    JOIN 
        supplier ON lineitem.l_suppkey = supplier.s_suppkey
    JOIN 
        nation ON supplier.s_nationkey = nation.n_nationkey
    GROUP BY 
        n_name
),
AvgRevenue AS (
    SELECT 
        AVG(revenue) AS avg_revenue
    FROM 
        TotalRevenue
),
RankedRevenues AS (
    SELECT 
        nation_name,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
    FROM 
        TotalRevenue
)
SELECT 
    rr.nation_name,
    rr.revenue,
    ar.avg_revenue,
    CASE 
        WHEN rr.revenue > ar.avg_revenue THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_comparison
FROM 
    RankedRevenues rr
JOIN 
    AvgRevenue ar ON 1=1
WHERE 
    rr.revenue_rank <= 5
ORDER BY 
    rr.revenue DESC;
