
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(LENGTH(s.s_comment)) AS avg_supplier_comment_length,
    MAX(CHAR_LENGTH(p.p_name)) AS max_part_name_length,
    MIN(CHAR_LENGTH(p.p_comment)) AS min_part_comment_length,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_acctbal > 0 
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    s.s_name, r.r_name, s.s_comment, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC, supplier_name ASC;
