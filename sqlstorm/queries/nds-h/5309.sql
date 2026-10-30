WITH TotalRevenue AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1996-01-01' AND 
        l.l_shipmode IN ('AIR', 'REG AIR')
    GROUP BY 
        n.n_name
),
RankedRevenue AS (
    SELECT 
        nation_name,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS rank
    FROM 
        TotalRevenue
)
SELECT 
    nation_name,
    revenue
FROM 
    RankedRevenue
WHERE 
    rank <= 10
ORDER BY 
    revenue DESC;
