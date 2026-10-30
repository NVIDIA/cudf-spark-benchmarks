SELECT 
    CONCAT_WS(' ', p.p_name, '(', p.p_container, ')') AS full_part_description,
    n.n_name AS nation_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%widget%'
    AND p.p_size BETWEEN 1 AND 10
    AND n.n_name IN ('USA', 'Canada')
GROUP BY 
    full_part_description, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    unique_customers_count DESC, avg_retail_price ASC;
