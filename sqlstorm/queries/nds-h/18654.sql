SELECT
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name,
    s.s_acctbal
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    p.p_size > 20
ORDER BY
    p.p_retailprice DESC
LIMIT 10;
