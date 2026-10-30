WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c_mktsegment, 
        COUNT(DISTINCT o_orderkey) AS order_count
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
    GROUP BY 
        c_mktsegment
)
SELECT 
    rs.c_mktsegment, 
    rs.revenue, 
    ts.order_count
FROM 
    RankedOrders rs
JOIN 
    TopSegments ts ON rs.c_mktsegment = ts.c_mktsegment
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    ts.order_count DESC, rs.revenue DESC;
