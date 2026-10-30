WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_spend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    ORDER BY 
        customer_spend DESC
    LIMIT 10
)
SELECT 
    r.o_orderkey,
    r.total_revenue,
    tc.c_name AS top_customer,
    tc.customer_spend
FROM 
    RankedOrders r
JOIN 
    TopCustomers tc ON r.o_orderkey = tc.c_custkey
WHERE 
    r.rank <= 5
ORDER BY 
    r.total_revenue DESC;