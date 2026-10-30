WITH TotalRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-01-01' + INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        tr.revenue,
        RANK() OVER (ORDER BY tr.revenue DESC) AS rnk
    FROM 
        TotalRevenue tr
    JOIN 
        customer c ON tr.c_custkey = c.c_custkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.revenue
FROM 
    TopCustomers tc
WHERE 
    tc.rnk <= 10
ORDER BY 
    tc.revenue DESC;