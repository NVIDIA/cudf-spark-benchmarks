WITH TotalSales AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        c.c_nationkey
), 
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ts.revenue, 0) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        TotalSales ts ON n.n_nationkey = ts.c_nationkey
)
SELECT 
    r.r_name AS region_name,
    SUM(nr.total_revenue) AS market_revenue
FROM 
    NationRevenue nr
JOIN 
    nation n ON nr.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    market_revenue DESC
LIMIT 10;