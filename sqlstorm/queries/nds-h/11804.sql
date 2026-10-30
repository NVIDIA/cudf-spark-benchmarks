SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name AS nation,
    o_orderdate
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
JOIN
    customer ON o_custkey = c_custkey
JOIN
    supplier ON l_suppkey = s_suppkey
JOIN
    nation ON s_nationkey = n_nationkey
WHERE
    o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY
    n_name, o_orderdate
ORDER BY
    total_revenue DESC;
