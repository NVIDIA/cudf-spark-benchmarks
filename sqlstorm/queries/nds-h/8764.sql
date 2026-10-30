
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
),
TopOrders AS (
    SELECT 
        customer_name,
        nation_name,
        o_orderkey,
        o_orderdate,
        o_totalprice
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)
SELECT 
    t.customer_name,
    t.nation_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.customer_name, t.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
