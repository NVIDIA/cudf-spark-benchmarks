WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tc.c_custkey, 
    tc.c_name, 
    tc.customer_revenue, 
    n.n_name AS nation_name, 
    r.r_name AS region_name
FROM 
    TopCustomers tc 
JOIN 
    nation n ON tc.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    tc.customer_revenue = (SELECT MAX(customer_revenue) FROM TopCustomers)
ORDER BY 
    tc.customer_revenue DESC;