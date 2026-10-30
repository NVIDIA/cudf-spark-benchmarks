
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice,
           1 AS level, CAST(p_name AS VARCHAR(255)) AS path
    FROM part
    WHERE p_size < 10
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ph.level + 1,
           CONCAT(ph.path, ' > ', p.p_name)
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size >= 10 AND ph.level < 5
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           MAX(ps.ps_availqty) AS max_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, n.n_comment,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_nationkey) AS rn
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT p.p_name, p.p_brand, p.p_retailprice,
       COALESCE(ss.total_supplycost, 0) AS total_supplycost,
       COALESCE(ss.part_count, 0) AS part_count,
       ni.n_name, ni.r_name, ni.n_comment
FROM part p
LEFT JOIN supplier_stats ss ON p.p_partkey = ss.s_suppkey
FULL OUTER JOIN nation_info ni ON ss.s_suppkey = ni.n_nationkey
WHERE (p.p_retailprice > 100 OR (p.p_name LIKE 'A%' AND p.p_container IS NULL))
AND NOT EXISTS (
    SELECT 1
    FROM lineitem l
    WHERE l.l_discount IS NOT NULL AND l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus != 'F'
    )
)
ORDER BY p.p_retailprice DESC, ni.n_name ASC
LIMIT 50 OFFSET 10;
