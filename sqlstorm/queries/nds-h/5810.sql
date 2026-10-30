WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_name,
        s.s_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
top_orders AS (
    SELECT *
    FROM ranked_orders
    WHERE order_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderdate,
    t.o_orderpriority,
    t.o_clerk,
    t.c_name AS customer_name,
    t.s_name AS supplier_name,
    COUNT(l.l_orderkey) AS line_items_count
FROM 
    top_orders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderstatus, t.o_totalprice, t.o_orderdate, t.o_orderpriority, t.o_clerk, t.c_name, t.s_name
ORDER BY 
    t.o_totalprice DESC;