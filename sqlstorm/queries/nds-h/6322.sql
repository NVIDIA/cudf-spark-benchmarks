WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate <= DATE '1997-12-31'
),
TopCustomers AS (
    SELECT 
        c_nationkey, 
        COUNT(DISTINCT o_orderkey) AS order_count, 
        SUM(o_totalprice) AS total_spent
    FROM 
        RankedOrders
    WHERE 
        rn <= 5
    GROUP BY 
        c_nationkey
)
SELECT 
    n.n_name, 
    tc.order_count, 
    tc.total_spent,
    AVG(tc.total_spent) OVER() AS avg_spent
FROM 
    TopCustomers tc
JOIN 
    nation n ON tc.c_nationkey = n.n_nationkey
ORDER BY 
    total_spent DESC
LIMIT 10;