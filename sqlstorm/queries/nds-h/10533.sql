SELECT
    p.p_partkey,
    p.p_name,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS revenue
FROM
    part p
JOIN
    lineitem L ON p.p_partkey = L.l_partkey
JOIN
    partsupp PS ON p.p_partkey = PS.ps_partkey
JOIN
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN
    nation N ON S.s_nationkey = N.n_nationkey
JOIN
    region R ON N.n_regionkey = R.r_regionkey
WHERE
    R.r_name = 'ASIA'
    AND L.l_shipdate >= DATE '1994-01-01'
    AND L.l_shipdate < DATE '1995-01-01'
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    revenue DESC;
