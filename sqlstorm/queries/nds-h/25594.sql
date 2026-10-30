
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_part_price,
    CONCAT(n.n_name, ' ', r.r_name) AS nation_region,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    customer c ON c.c_custkey = l.l_orderkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
AND 
    l.l_shipdate < DATE '1998-01-01' 
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_retailprice, p.p_comment 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000 
ORDER BY 
    unique_parts_count DESC, total_revenue DESC;
