SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderdate
FROM
    orders
JOIN
    lineitem ON o_orderkey = l_orderkey
WHERE
    l_shipdate >= DATE '1995-01-01' AND l_shipdate <= DATE '1996-12-31'
GROUP BY
    o_orderdate
ORDER BY
    o_orderdate;
