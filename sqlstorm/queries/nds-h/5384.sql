WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c_mktsegment, 
        SUM(revenue) AS segment_revenue
    FROM 
        RankedOrders
    WHERE 
        rk <= 5
    GROUP BY 
        c_mktsegment
)
SELECT 
    ts.c_mktsegment,
    ts.segment_revenue,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    TopSegments ts
JOIN 
    customer c ON ts.c_mktsegment = c.c_mktsegment
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    ts.c_mktsegment, ts.segment_revenue, r.r_name
ORDER BY 
    ts.segment_revenue DESC;
