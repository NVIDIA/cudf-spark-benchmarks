WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
        AND o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.total_revenue
FROM 
    RankedOrders ro
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_orderdate, ro.total_revenue DESC;