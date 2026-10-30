WITH RevenueDetails AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        rd.total_revenue,
        rd.total_orders,
        RANK() OVER (ORDER BY rd.total_revenue DESC) AS revenue_rank
    FROM 
        RevenueDetails rd
    JOIN 
        customer c ON rd.c_custkey = c.c_custkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_revenue,
    tc.total_orders
FROM 
    TopCustomers tc
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.total_revenue DESC;