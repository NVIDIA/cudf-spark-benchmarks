WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority
),
TopPriorityOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    c.c_name, 
    c.c_acctbal, 
    SUM(t.total_revenue) AS customer_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopPriorityOrders t ON o.o_orderkey = t.o_orderkey
GROUP BY 
    c.c_name, 
    c.c_acctbal
ORDER BY 
    customer_revenue DESC
LIMIT 10;
