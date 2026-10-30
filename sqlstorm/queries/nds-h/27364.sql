
SELECT 
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    REPLACE(UPPER(p.p_comment), ' ', '-') AS formatted_comment,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate >= '1996-01-01' 
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    CONCAT(s.s_name, ' ', s.s_address), 
    SUBSTRING(p.p_name, 1, 20), 
    REPLACE(UPPER(p.p_comment), ' ', '-'), 
    r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, region_name ASC;
