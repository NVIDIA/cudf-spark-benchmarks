SELECT
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_partkey, p.p_name
ORDER BY
    total_avail_qty DESC
LIMIT 10;
