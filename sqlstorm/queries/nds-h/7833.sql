
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1994-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    c.c_name,
    c.c_address,
    tro.o_orderkey,
    tro.total_revenue,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered,
    SUM(l.l_quantity) AS total_quantity_ordered
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopRevenueOrders tro ON o.o_orderkey = tro.o_orderkey
JOIN 
    lineitem l ON tro.o_orderkey = l.l_orderkey
GROUP BY 
    c.c_name, c.c_address, tro.o_orderkey, tro.total_revenue
ORDER BY 
    tro.total_revenue DESC;
