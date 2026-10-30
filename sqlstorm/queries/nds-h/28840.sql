
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey AS order_id, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Supplier ', s.s_name, ' provided ', p.p_name) AS supply_details
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, p.p_comment
ORDER BY 
    total_revenue DESC;
