SELECT
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY
    c.c_name, o.o_orderkey
ORDER BY
    revenue DESC
LIMIT 10;
