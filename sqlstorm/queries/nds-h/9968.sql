
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.total_revenue,
        ROW_NUMBER() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders o
)
SELECT 
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    SUM(o.total_revenue) AS total_revenue
FROM 
    TopOrders o
WHERE 
    o.revenue_rank <= 10
GROUP BY 
    o.o_orderdate, o.total_revenue
ORDER BY 
    o.o_orderdate;
