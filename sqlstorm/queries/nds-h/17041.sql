SELECT
    p.p_mfgr,
    SUM(ps.ps_availqty) AS total_avail_qty,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_mfgr
ORDER BY
    total_supply_cost DESC
LIMIT 10;
