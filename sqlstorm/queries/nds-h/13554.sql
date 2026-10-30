SELECT
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    part p
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    revenue DESC
LIMIT 10;