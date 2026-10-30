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
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
CustomerRevenue AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.total_revenue) AS total_customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cr.c_custkey, 
        cr.c_name, 
        cr.total_customer_revenue,
        RANK() OVER (ORDER BY cr.total_customer_revenue DESC) AS revenue_rank
    FROM 
        CustomerRevenue cr
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    ROUND(tc.total_customer_revenue, 2) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
WHERE 
    tc.revenue_rank <= 10
GROUP BY 
    tc.c_custkey, tc.c_name, tc.total_customer_revenue
ORDER BY 
    total_revenue DESC;