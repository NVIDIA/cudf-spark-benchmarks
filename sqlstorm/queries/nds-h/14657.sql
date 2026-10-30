SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_extended_price DESC
LIMIT 100;
