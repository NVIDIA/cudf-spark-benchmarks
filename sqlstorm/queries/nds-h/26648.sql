SELECT 
    p.p_partkey, 
    p.p_name, 
    CONCAT('Manufacturer: ', p.p_mfgr, ' - Brand: ', p.p_brand, ' - Type: ', p.p_type) AS description,
    SUM(CASE 
        WHEN l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS recent_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%brass%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
ORDER BY 
    recent_sales DESC, unique_customers DESC
LIMIT 100;