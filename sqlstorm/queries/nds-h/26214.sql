SELECT 
    CONCAT('Supplier: ', s_name, ' - Part: ', p_name, ' - Comment: ', ps_comment) AS detailed_info,
    l_shipdate,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s_name, p_name, ps_comment, l_shipdate
ORDER BY 
    revenue DESC
LIMIT 10;