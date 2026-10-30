
SELECT 
    CONCAT(p.p_name, ' (', s.s_name, ')') AS product_supplier,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    CHAR_LENGTH(p.p_name) > 10
    AND l.l_shipmode = 'AIR'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price_after_discount DESC;
