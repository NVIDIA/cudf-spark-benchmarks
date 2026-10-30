SELECT
    l.l_partkey,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    o.o_orderdate
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    l.l_partkey, o.o_orderdate
ORDER BY
    total_revenue DESC
LIMIT 100;