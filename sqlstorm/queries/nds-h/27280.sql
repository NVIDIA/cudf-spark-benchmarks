
SELECT
    SUM(CASE 
            WHEN POSITION('special' IN LOWER(p_comment)) > 0 THEN 1 
            ELSE 0 
        END) AS special_part_count,
    AVG(p_retailprice) AS average_retail_price,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers_count,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size > 10
GROUP BY r.r_name, n.n_name, p_comment, p_retailprice
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY region_name, nation_name;
