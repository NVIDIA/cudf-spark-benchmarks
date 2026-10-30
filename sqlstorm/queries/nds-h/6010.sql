WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
top_customers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        ro.total_sale
    FROM 
        ranked_orders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        ro.rank <= 5
)
SELECT 
    tc.c_name,
    tc.c_acctbal,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(tc.total_sale) AS total_spent
FROM 
    top_customers tc
JOIN 
    orders o ON tc.o_orderkey = o.o_orderkey
GROUP BY 
    tc.c_name, tc.c_acctbal
ORDER BY 
    total_spent DESC
LIMIT 10;