WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerRevenue AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.total_revenue) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    WHERE 
        ro.rnk = 1
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cr.revenue, 
        RANK() OVER (ORDER BY cr.revenue DESC) AS revenue_rank
    FROM 
        CustomerRevenue cr
    JOIN 
        customer c ON cr.c_custkey = c.c_custkey
)
SELECT 
    tc.c_custkey, 
    tc.c_name, 
    tc.revenue
FROM 
    TopCustomers tc
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.revenue DESC;