WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        r.c_name,
        SUM(ro.total_revenue) AS customer_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(ro.total_revenue) DESC) AS rank
    FROM 
        RankedOrders ro
    JOIN 
        customer r ON ro.c_name = r.c_name
    GROUP BY 
        r.c_name
)
SELECT 
    tc.c_name,
    tc.customer_revenue,
    tc.rank
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.customer_revenue DESC;
