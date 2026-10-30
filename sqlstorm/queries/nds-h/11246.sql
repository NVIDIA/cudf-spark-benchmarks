SELECT
    L.l_orderkey,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS revenue,
    O.o_orderdate,
    C.c_name,
    S.s_name,
    P.p_name,
    N.n_name,
    R.r_name
FROM
    lineitem L
JOIN
    orders O ON L.l_orderkey = O.o_orderkey
JOIN
    customer C ON O.o_custkey = C.c_custkey
JOIN
    supplier S ON L.l_suppkey = S.s_suppkey
JOIN
    partsupp PS ON L.l_partkey = PS.ps_partkey AND S.s_suppkey = PS.ps_suppkey
JOIN
    part P ON PS.ps_partkey = P.p_partkey
JOIN
    nation N ON S.s_nationkey = N.n_nationkey
JOIN
    region R ON N.n_regionkey = R.r_regionkey
WHERE
    O.o_orderdate >= DATE '1997-01-01'
    AND O.o_orderdate < DATE '1998-01-01'
GROUP BY
    L.l_orderkey,
    O.o_orderdate,
    C.c_name,
    S.s_name,
    P.p_name,
    N.n_name,
    R.r_name
ORDER BY
    revenue DESC;