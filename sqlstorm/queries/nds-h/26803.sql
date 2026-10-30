
SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS detail,
    CASE 
        WHEN p.p_retailprice < 100 THEN 'Low Price'
        WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Medium Price'
        ELSE 'High Price'
    END AS price_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue
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
    s.s_name LIKE '%specific%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_retailprice
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, price_category ASC;
