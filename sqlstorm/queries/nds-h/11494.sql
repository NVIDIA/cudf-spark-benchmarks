SELECT
    S.s_name,
    N.n_name,
    SUM(PS.ps_supplycost * PS.ps_availqty) AS total_cost
FROM
    supplier S
JOIN
    partsupp PS ON S.s_suppkey = PS.ps_suppkey
JOIN
    nation N ON S.s_nationkey = N.n_nationkey
GROUP BY
    S.s_name, N.n_name
ORDER BY
    total_cost DESC
LIMIT 10;
