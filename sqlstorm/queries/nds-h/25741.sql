SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    concat('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info,
    substring(l.l_comment from 1 for 20) AS short_comment,
    trim(both ' ' from p.p_comment) AS trimmed_comment 
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
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipmode LIKE '%AIR%'
ORDER BY 
    extended_price DESC 
LIMIT 50;
