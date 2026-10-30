WITH RevenueData AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
        AND l.l_shipmode IN ('AIR', 'SHIP')
    GROUP BY 
        n.n_name
),
RankedRevenue AS (
    SELECT 
        nation,
        total_revenue,
        order_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueData
)
SELECT 
    nation,
    total_revenue,
    order_count,
    revenue_rank
FROM 
    RankedRevenue
WHERE 
    revenue_rank <= 10
ORDER BY 
    total_revenue DESC;