
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    r.r_name AS region_name,
    SUM(t.total_revenue) AS total_revenue_generated,
    COUNT(DISTINCT t.o_orderkey) AS total_orders,
    AVG(t.total_revenue) AS average_order_value
FROM 
    TopRevenueOrders t
JOIN 
    customer c ON c.c_custkey = t.o_orderkey
JOIN 
    supplier s ON s.s_suppkey = c.c_nationkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_generated DESC;
