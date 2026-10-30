WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(co.total_revenue) AS total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    tc.c_name,
    tc.total_spent,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    AVG(co.total_revenue) AS avg_order_value
FROM 
    TopCustomers tc
JOIN 
    CustomerOrders co ON tc.c_custkey = co.c_custkey
GROUP BY 
    tc.c_name, tc.total_spent
ORDER BY 
    avg_order_value DESC;
