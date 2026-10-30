SELECT
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    lineitem l ON ps.ps_suppkey = l.l_suppkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY
    p.p_name
ORDER BY
    total_quantity DESC
LIMIT 10;
