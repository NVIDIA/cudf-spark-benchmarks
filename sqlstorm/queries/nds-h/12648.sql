SELECT
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    o.o_orderstatus,
    c.c_mktsegment
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-12-31'
GROUP BY
    l.l_orderkey, o.o_orderstatus, c.c_mktsegment
ORDER BY
    total_revenue DESC
LIMIT 100;