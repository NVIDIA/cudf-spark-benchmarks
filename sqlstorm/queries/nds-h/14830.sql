SELECT
    p.p_brand,
    p.p_type,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
GROUP BY
    p.p_brand, p.p_type
ORDER BY
    total_cost DESC
LIMIT 10;