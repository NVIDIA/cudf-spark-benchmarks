SELECT 
    l_orderkey,
    SUM(l_extendedprice) AS total_revenue,
    COUNT(DISTINCT l_partkey) AS number_of_parts,
    AVG(l_discount) AS average_discount,
    SUM(l_tax) AS total_tax
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    l_orderkey
ORDER BY 
    total_revenue DESC
LIMIT 100;