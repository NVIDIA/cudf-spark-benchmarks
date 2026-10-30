WITH TotalRevenue AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
AverageRevenue AS (
    SELECT 
        AVG(revenue) AS avg_revenue
    FROM 
        TotalRevenue
),
HighRevenueNations AS (
    SELECT 
        nation_name,
        revenue
    FROM 
        TotalRevenue
    WHERE 
        revenue > (SELECT avg_revenue FROM AverageRevenue)
)
SELECT 
    nation_name,
    revenue
FROM 
    HighRevenueNations
ORDER BY 
    revenue DESC
LIMIT 10;