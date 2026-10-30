SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    l.l_quantity, 
    l.l_extendedprice, 
    l.l_discount, 
    l.l_tax, 
    r.r_name AS region_name,
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_product,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CONCAT(p.p_comment, ' ', c.c_comment) AS combined_comments
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
    part p ON l.l_partkey = p.p_partkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l.l_discount BETWEEN 0.05 AND 0.20 
ORDER BY 
    return_status DESC, 
    combined_comments ASC;