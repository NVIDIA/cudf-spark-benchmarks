SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price
FROM
    part AS p
JOIN
    lineitem AS l ON p.p_partkey = l.l_partkey
GROUP BY
    p.p_partkey, p.p_name, p.p_mfgr
ORDER BY
    total_quantity DESC
LIMIT 100;
