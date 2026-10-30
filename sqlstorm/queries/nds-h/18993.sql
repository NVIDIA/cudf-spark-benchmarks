SELECT
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_name
ORDER BY
    total_available_quantity DESC
LIMIT 10;
