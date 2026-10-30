SELECT
    n_name,
    SUM(o_totalprice) AS total_sales
FROM
    nation
JOIN
    supplier ON n_nationkey = s_nationkey
JOIN
    customer ON s_suppkey = c_custkey
JOIN
    orders ON c_custkey = o_custkey
GROUP BY
    n_name
ORDER BY
    total_sales DESC;
