WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_retailprice > 50.00 AND p.p_type LIKE '%Plastic%'
), combined_data AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        r.r_name AS region_name,
        rp.s_name AS supplier_name,
        rp.rank AS supplier_rank,
        fp.p_name AS part_name,
        fp.comment_length
    FROM partsupp ps
    JOIN ranked_suppliers rp ON ps.ps_suppkey = rp.s_suppkey
    JOIN filtered_parts fp ON ps.ps_partkey = fp.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    COUNT(DISTINCT supplier_name) AS total_suppliers,
    AVG(comment_length) AS avg_comment_length,
    MAX(comment_length) AS max_comment_length
FROM combined_data
GROUP BY region_name
ORDER BY total_suppliers DESC, region_name;
