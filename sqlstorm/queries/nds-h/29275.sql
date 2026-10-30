
SELECT 
    CONCAT('Part Name: ', p.p_name, ', Manufacturer: ', p.p_mfgr, 
           ', Retail Price: $', CAST(ROUND(p.p_retailprice, 2) AS STRING), 
           ', Comment: ', CASE 
                           WHEN LENGTH(p.p_comment) > 10 THEN CONCAT(SUBSTRING(p.p_comment, 1, 10), '...') 
                           ELSE p.p_comment 
                         END) AS formatted_part_info,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND r.r_name LIKE '%Asia%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, p.p_comment, 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    unique_customers DESC, p.p_name;
