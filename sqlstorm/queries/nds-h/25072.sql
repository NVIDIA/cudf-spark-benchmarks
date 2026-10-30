SELECT 
    CONCAT('Supplier: ', s.s_name, 
           ' | Part: ', p.p_name, 
           ' | Quantity: ', ps.ps_availqty, 
           ' | Cost: $', ROUND(ps.ps_supplycost, 2), 
           ' | Region: ', r.r_name) AS benchmark_info
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
    LENGTH(p.p_name) > 10
    AND ps.ps_availqty BETWEEN 10 AND 100
    AND s.s_comment LIKE '%reliable%'
ORDER BY 
    s.s_suppkey DESC, 
    ps.ps_supplycost ASC
LIMIT 50;
