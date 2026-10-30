
SELECT 
    p.p_name,
    s.s_name,
    SUBSTRING(s.s_address, 1, 20) AS short_address,
    CONCAT('Region: ', r.r_name) AS region_info,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT c.c_custkey) AS customer_count
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
    orders o ON p.p_partkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 25 
    AND s.s_acctbal > 1000 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, short_address, region_info, comment_length
ORDER BY 
    comment_length DESC, customer_count DESC;
