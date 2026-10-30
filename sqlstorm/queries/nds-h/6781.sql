
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
    ORDER BY 
        total_revenue DESC
),
TopCustomers AS (
    SELECT 
        c_name,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders
)
SELECT 
    rg.r_name AS region,
    SUM(r.revenue) AS total_revenue
FROM (
    SELECT 
        n.n_regionkey,
        SUM(ro.total_revenue) AS revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
) r
JOIN region rg ON r.n_regionkey = rg.r_regionkey
GROUP BY 
    rg.r_name
ORDER BY 
    total_revenue DESC;
