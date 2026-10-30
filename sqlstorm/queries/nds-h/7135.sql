WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY SUM(ro.revenue) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.revenue_rank,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    CustomerRevenue cr
JOIN 
    orders o ON cr.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    cr.c_custkey, cr.c_name, cr.revenue_rank
HAVING 
    cr.revenue_rank <= 10
ORDER BY 
    total_revenue DESC;
