SELECT
    p.p_name,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS revenue
FROM
    part p
JOIN
    lineitem ls ON p.p_partkey = ls.l_partkey
GROUP BY
    p.p_name
ORDER BY
    revenue DESC
LIMIT 10;
