SELECT
    p.p_mfgr,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supplycost,
    AVG(p.p_retailprice) AS avg_retailprice
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
    r.r_name = 'EUROPE'
GROUP BY
    p.p_mfgr
ORDER BY
    supplier_count DESC
LIMIT 10;
