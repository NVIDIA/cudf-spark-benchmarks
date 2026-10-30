
SELECT 
    p.p_name, 
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name,
    LEFT(p.p_comment, POSITION(' ' IN p.p_comment || ' ') - 1) AS truncated_comment,
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_details
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_comment, s.s_address
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, average_discount ASC;
