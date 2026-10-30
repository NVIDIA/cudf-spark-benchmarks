SELECT
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_partkey, p.p_name
HAVING
    SUM(ps.ps_availqty) > 100
ORDER BY
    avg_supply_cost DESC;
