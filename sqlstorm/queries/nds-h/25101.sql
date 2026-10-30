SELECT
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    ARRAY_AGG(DISTINCT r.r_name) AS regions_supplied,
    CONCAT('Brand: ', p.p_brand, ', Manufacturer: ', p.p_mfgr, ', Total Qty: ', SUM(ps.ps_availqty)) AS summary
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_brand LIKE 'Brand%'
GROUP BY
    p.p_name, p.p_brand, p.p_mfgr
HAVING
    SUM(ps.ps_availqty) > 1000
ORDER BY
    total_available_quantity DESC;
