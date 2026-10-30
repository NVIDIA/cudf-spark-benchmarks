SELECT
    s_name,
    SUM(ps_supplycost * ps_availqty) AS total_supplycost
FROM
    supplier
JOIN
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
GROUP BY
    s_name
ORDER BY
    total_supplycost DESC
LIMIT 10;
