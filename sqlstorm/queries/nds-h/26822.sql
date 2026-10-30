SELECT
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    CONCAT(p.p_type, ' - ', p.p_container) AS part_details,
    r.r_name AS region_name
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    l.l_shipmode LIKE '%AIR%'
    AND l.l_returnflag = 'N'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    s.s_name, p.p_name, r.r_name, p.p_type, p.p_container
ORDER BY
    total_available_quantity DESC, average_price ASC;