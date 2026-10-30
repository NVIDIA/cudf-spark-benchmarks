WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count,
        o.o_orderdate,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
), RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.order_count,
        os.o_orderdate,
        os.c_mktsegment,
        RANK() OVER (PARTITION BY os.c_mktsegment ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
)
SELECT 
    ro.c_mktsegment,
    COUNT(ro.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS avg_revenue,
    MAX(ro.total_revenue) AS max_revenue,
    MIN(ro.total_revenue) AS min_revenue
FROM 
    RankedOrders ro
WHERE 
    ro.revenue_rank <= 10
GROUP BY 
    ro.c_mktsegment
ORDER BY 
    ro.c_mktsegment;