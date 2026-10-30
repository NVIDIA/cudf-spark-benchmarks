SELECT
    p.p_partkey,
    p.p_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue,
    o.o_orderdate
FROM
    part AS p
JOIN
    lineitem AS lp ON p.p_partkey = lp.l_partkey
JOIN
    orders AS o ON lp.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= DATE '1994-01-01'
    AND o.o_orderdate < DATE '1995-01-01'
GROUP BY
    p.p_partkey, p.p_name, o.o_orderdate
ORDER BY
    revenue DESC
LIMIT 10;
