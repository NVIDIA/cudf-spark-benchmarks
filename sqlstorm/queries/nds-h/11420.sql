SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(year from o_orderdate) AS order_year
FROM
    lineitem
JOIN
    orders ON l_orderkey = o_orderkey
JOIN
    customer ON o_custkey = c_custkey
JOIN
    nation ON c_nationkey = n_nationkey
WHERE
    o_orderdate >= DATE '1995-01-01' AND o_orderdate < DATE '1996-01-01'
GROUP BY
    n_name, order_year
ORDER BY
    revenue DESC, n_name;
