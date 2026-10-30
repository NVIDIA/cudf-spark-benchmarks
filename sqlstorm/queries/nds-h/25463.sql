
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_comment), '; ') AS supplier_comments,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_discounted_sales,
    REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z0-9 ]', '') AS cleaned_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
WHERE 
    p.p_type LIKE '%WHEELS%'
GROUP BY 
    p.p_name, cleaned_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_discounted_sales DESC
LIMIT 10;
