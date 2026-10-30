
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ' | Address: ', s.s_address) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS average_price,
    CASE 
        WHEN p.p_size < 20 THEN 'Small'
        WHEN p.p_size BETWEEN 20 AND 40 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
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
WHERE 
    p.p_mfgr LIKE 'Manufacturer%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment, s.s_name, s.s_address, p.p_size
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    average_price DESC, size_category;
