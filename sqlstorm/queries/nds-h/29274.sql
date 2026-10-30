SELECT 
    CONCAT('Supplier Name: ', s.s_name, ', Part Name: ', p.p_name, ', Order Priority: ', o.o_orderpriority) AS string_info,
    SUBSTRING(s.s_address, 1, 20) AS short_address,
    LENGTH(s.s_comment) AS comment_length,
    REPLACE(p.p_comment, 'quick', 'fast') AS modified_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS geographic_info,
    CASE 
        WHEN ps.ps_availqty > 100 THEN 'High Availability' 
        WHEN ps.ps_availqty BETWEEN 50 AND 100 THEN 'Moderate Availability' 
        ELSE 'Low Availability' 
    END AS availability_status
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (s.s_name LIKE '%Inc%' OR p.p_name LIKE '%Widget%')
    AND o.o_orderstatus = 'O'
ORDER BY 
    availability_status, comment_length DESC;
