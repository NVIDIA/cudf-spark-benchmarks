
SELECT 
    s_name AS supplier_name, 
    n_name AS nation_name, 
    COUNT(DISTINCT o_orderkey) AS total_orders, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    SUBSTRING(p_name FROM 1 FOR 20) AS short_part_name,
    CASE 
        WHEN p_size > 30 THEN 'Large' 
        WHEN p_size BETWEEN 15 AND 30 THEN 'Medium'
        ELSE 'Small' 
    END AS part_size_category,
    CONCAT(s_address, ', ', n_name) AS supplier_location
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1998-01-01'
GROUP BY 
    s.s_suppkey, s_name, n_name, p_name, p_size, s_address
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;
