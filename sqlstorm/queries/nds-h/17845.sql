SELECT
    p.p_brand,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
FROM
    lineitem l
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY
    p.p_brand
ORDER BY
    avg_price DESC
LIMIT 10;
