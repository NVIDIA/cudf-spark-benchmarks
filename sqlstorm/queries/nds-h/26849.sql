
WITH filtered_parts AS (
    SELECT p_partkey, 
           p_name, 
           p_brand, 
           p_type, 
           p_size, 
           p_retailprice, 
           SUBSTRING(p_comment, 1, 15) AS short_comment
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size < 20)
),
supplier_info AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           CONCAT(s.s_name, ' | ', s.s_address) AS supplier_details
    FROM supplier s
    WHERE LENGTH(s.s_comment) > 50
),
nation_summary AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT fp.p_partkey, 
       fp.p_name, 
       fp.p_brand, 
       fp.p_type, 
       fp.p_size, 
       fp.p_retailprice, 
       fp.short_comment, 
       si.supplier_details, 
       ns.n_name, 
       ns.supplier_count
FROM filtered_parts fp
JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN supplier_info si ON ps.ps_suppkey = si.s_suppkey
JOIN nation_summary ns ON si.s_nationkey = ns.n_nationkey
WHERE fp.p_name LIKE '%widget%'
ORDER BY fp.p_brand, fp.p_retailprice DESC;
