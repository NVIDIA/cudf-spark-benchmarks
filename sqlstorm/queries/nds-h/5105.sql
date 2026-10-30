WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c.c_mktsegment,
        SUM(total_revenue) AS segment_revenue
    FROM 
        RankedOrders r
    JOIN 
        customer c ON r.o_orderkey = c.c_custkey
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.c_mktsegment,
    r.total_revenue,
    t.segment_revenue,
    (r.total_revenue / NULLIF(t.segment_revenue, 0)) * 100 AS revenue_percentage
FROM 
    RankedOrders r
JOIN 
    TopSegments t ON r.c_mktsegment = t.c_mktsegment
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.c_mktsegment, r.total_revenue DESC;