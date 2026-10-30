SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_retailprice
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY
    p.p_name
ORDER BY
    total_quantity DESC
LIMIT 10;
