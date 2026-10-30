WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.revenue) AS total_revenue,
        COUNT(ro.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    WHERE 
        ro.rank_revenue <= 10
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.total_revenue,
    cr.total_orders,
    CASE 
        WHEN cr.total_revenue > 100000 THEN 'High Value Customer'
        WHEN cr.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category 
FROM 
    CustomerRevenue cr
ORDER BY 
    cr.total_revenue DESC;
