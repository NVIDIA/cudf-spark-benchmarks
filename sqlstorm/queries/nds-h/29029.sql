
SELECT
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(LENGTH(p.p_comment)) AS min_comment_length,
    UPPER(SUBSTRING(p.p_comment, 1, 10)) AS comment_prefix,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
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
    p.p_name LIKE '%widget%'
    AND ps.ps_availqty > 0
GROUP BY
    p.p_name, r.r_name, n.n_name, p.p_retailprice, p.p_comment, s.s_name, s.s_address
ORDER BY
    total_available_quantity DESC, average_supply_cost ASC;
