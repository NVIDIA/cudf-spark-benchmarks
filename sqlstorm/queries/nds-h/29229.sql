
SELECT 
    CONCAT(s.s_name, ' (', c.c_name, ')') AS supplier_customer,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT l.l_orderkey) AS line_items,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_line,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', p.p_comment), '; ') AS products_sold
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    s.s_suppkey, s.s_name, c.c_custkey, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
