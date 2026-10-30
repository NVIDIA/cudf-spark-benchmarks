
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
)
SELECT 
    ro.revenue_rank,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.total_revenue
FROM 
    ranked_orders ro
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ro.o_orderdate DESC, ro.total_revenue DESC;
