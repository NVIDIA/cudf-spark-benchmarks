SELECT
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(YEAR FROM o_orderdate) AS year
FROM
    customer
JOIN
    orders ON c_custkey = o_custkey
JOIN
    lineitem ON o_orderkey = l_orderkey
JOIN
    supplier ON l_suppkey = s_suppkey
JOIN
    nation ON s_nationkey = n_nationkey
WHERE
    o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    AND n_name LIKE 'N%'
GROUP BY
    n_name, year
ORDER BY
    revenue DESC;
