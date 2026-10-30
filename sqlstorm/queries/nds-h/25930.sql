
SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location,
    LEFT(p.p_comment, 10) AS short_comment,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, p.p_comment
ORDER BY 
    total_quantity DESC, average_price ASC
LIMIT 10;
