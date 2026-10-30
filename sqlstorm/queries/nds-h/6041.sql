WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.total_revenue
FROM 
    RankedOrders r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.o_orderdate, r.total_revenue DESC;