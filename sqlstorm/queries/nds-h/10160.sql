SELECT
    p.p_name,
    supplier.s_name,
    SUM(l.l_quantity) AS total_quantity
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier ON ps.ps_suppkey = supplier.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY
    p.p_name, supplier.s_name
ORDER BY
    total_quantity DESC
LIMIT 100;