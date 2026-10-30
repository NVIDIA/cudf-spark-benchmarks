WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
RankedRevenue AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        c_name, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders
)
SELECT 
    rr.o_orderkey, 
    rr.o_orderdate, 
    rr.c_name, 
    rr.total_revenue
FROM 
    RankedRevenue rr
WHERE 
    rr.revenue_rank <= 10
ORDER BY 
    rr.total_revenue DESC;
