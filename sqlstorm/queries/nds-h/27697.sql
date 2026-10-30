SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT p.p_partkey) AS total_parts, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    STRING_AGG(DISTINCT s.s_comment || ' (' || CAST(s.s_acctbal AS STRING) || ')', '; ') AS supplier_details
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_parts DESC, region_name, nation_name;