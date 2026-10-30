
SELECT
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    MIN(p.p_retailprice) AS min_retail_price,
    MAX(p.p_retailprice) AS max_retail_price,
    CONCAT(SUBSTRING(p.p_name, 1, 15), '...') AS short_name,
    TRIM(BOTH ' ' FROM p.p_comment) AS clean_comment,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderstatus = 'O') AS active_customers
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    p.p_type LIKE '%metric%' 
    AND s.s_comment NOT LIKE '%inconvenient%'
GROUP BY
    p.p_brand, p.p_name, p.p_comment
HAVING
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY
    average_retail_price DESC
LIMIT 10;
