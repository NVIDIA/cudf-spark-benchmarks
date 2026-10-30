WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cr.c_custkey,
        cr.c_name,
        cr.customer_total_revenue,
        RANK() OVER (ORDER BY cr.customer_total_revenue DESC) AS customer_rank
    FROM 
        CustomerRevenue cr
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.customer_total_revenue
FROM 
    TopCustomers tc
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.customer_total_revenue DESC;