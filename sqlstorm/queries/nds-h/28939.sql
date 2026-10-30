SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
    r.r_name AS region_name, 
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%%special%%' 
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, p.p_type, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_sales DESC;