
SELECT 
    CONCAT('Part Name: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type, 
           ', Container: ', p.p_container, ', Comment: ', p.p_comment) AS part_details,
    s.s_name AS supplier_name,
    CONCAT(c.c_name, ' (', c.c_address, ')') AS customer_info,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
WHERE 
    p.p_retailprice > 100.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, p.p_type, p.p_container, p.p_comment, s.s_name, 
    c.c_name, c.c_address, o.o_orderkey, o.o_orderdate
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000.00
ORDER BY 
    total_revenue DESC;
