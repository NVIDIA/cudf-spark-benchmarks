SELECT
    CONCAT('Part: ', p.p_name, ' - Supplier: ', s.s_name, ' - Nation: ', n.n_name) AS benchmark_string,
    COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
WHERE
    p.p_brand LIKE 'Brand%' AND
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    p.p_partkey, p.p_name, s.s_name, n.n_name
ORDER BY
    benchmark_string
LIMIT 100;