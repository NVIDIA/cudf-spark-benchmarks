WITH TotalSales AS (
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
AverageSales AS (
    SELECT 
        AVG(total_revenue) AS avg_revenue,
        MAX(total_revenue) AS max_revenue,
        MIN(total_revenue) AS min_revenue
    FROM 
        TotalSales
),
TopNations AS (
    SELECT 
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales
)

SELECT 
    T.nation,
    T.total_revenue,
    A.avg_revenue,
    A.max_revenue,
    A.min_revenue
FROM 
    TopNations T
CROSS JOIN 
    AverageSales A
WHERE 
    T.revenue_rank <= 5
ORDER BY 
    T.total_revenue DESC;