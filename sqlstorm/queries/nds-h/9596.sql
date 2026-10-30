WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS total_spent,
        RANK() OVER (ORDER BY SUM(ro.total_revenue) DESC) AS rank
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    MAX(ro.o_orderdate) AS last_order_date
FROM 
    TopCustomers tc
JOIN 
    RankedOrders ro ON tc.c_custkey = ro.o_orderkey
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.c_custkey, tc.c_name, tc.total_spent
ORDER BY 
    tc.total_spent DESC;