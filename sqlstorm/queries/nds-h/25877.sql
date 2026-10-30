SELECT
    CONCAT('Supplier Name: ', s_name) AS supplier_info,
    SUBSTRING(s_address, 1, 20) AS short_address,
    CASE
        WHEN LENGTH(s_comment) > 50 THEN CONCAT(SUBSTRING(s_comment, 1, 47), '...')
        ELSE s_comment
    END AS brief_comment,
    COUNT(DISTINCT ps_partkey) AS part_count,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost
FROM
    supplier
JOIN
    partsupp ON s_suppkey = ps_suppkey
JOIN
    part ON ps_partkey = p_partkey
WHERE
    p_name LIKE '%steel%'
GROUP BY
    s_suppkey, s_name, s_address, s_comment
ORDER BY
    total_available_quantity DESC
LIMIT 10;
