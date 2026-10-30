WITH customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, o.o_orderpriority
),
high_value_customers AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY c.total_revenue DESC) AS rn
    FROM 
        customer_orders c
    WHERE 
        c.total_revenue > 10000
)
SELECT 
    c.c_name,
    c.c_address,
    c.o_orderkey,
    c.o_orderdate,
    c.total_revenue,
    c.total_lineitems
FROM 
    high_value_customers c
WHERE 
    c.rn = 1
ORDER BY 
    c.total_revenue DESC
LIMIT 10;