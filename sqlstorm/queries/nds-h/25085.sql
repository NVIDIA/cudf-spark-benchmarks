
SELECT
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    p.p_name LIKE '%steel%'
    AND s.s_comment NOT LIKE '%foreign%'
GROUP BY
    s.s_name, n.n_name, r.r_name
HAVING
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY
    total_supply_cost DESC, supplier_info ASC;
