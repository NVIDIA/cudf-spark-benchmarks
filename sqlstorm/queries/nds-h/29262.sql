
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUBSTRING(p.p_comment, 1, 20) AS truncated_comment,
    CONCAT('Order Date: ', CAST(o.o_orderdate AS CHAR(10))) AS order_details,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_type LIKE 'rubber%'
AND 
    o.o_orderdate >= DATE '1996-01-01' 
AND 
    o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, p.p_comment, o.o_orderdate
ORDER BY 
    total_revenue DESC
LIMIT 10;
