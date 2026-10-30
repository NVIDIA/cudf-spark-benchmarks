SELECT
    p.p_partkey,
    p.p_name,
    SUM(ls.l_quantity) AS total_quantity_sold,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue
FROM
    part p
JOIN
    lineitem ls ON p.p_partkey = ls.l_partkey
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_revenue DESC
LIMIT 10;
