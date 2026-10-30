SELECT 
    p.p_name, 
    p.p_brand, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
WHERE 
    p.p_type LIKE '%plastic%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUBSTRING(p.p_comment, 1, 10)
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    revenue_rank ASC;