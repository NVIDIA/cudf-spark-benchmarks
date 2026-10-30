
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT l.l_partkey) AS unique_parts_sold
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01'
    AND l.l_shipdate >= '1996-01-01' 
    AND l.l_shipdate < '1997-01-01'
GROUP BY 
    c.c_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC,
    unique_parts_sold DESC
LIMIT 10;
