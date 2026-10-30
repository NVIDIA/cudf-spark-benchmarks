WITH RecursiveStringProcessing AS (
    SELECT 
        SUBSTRING(p_name, 1, 10) AS processed_name, 
        p_partkey, 
        LENGTH(p_name) AS original_length,
        REPLACE(p_comment, ' ', '') AS no_space_comment
    FROM part
    WHERE p_size > 10
),
AggregatedData AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(original_length) AS avg_length,
        COUNT(DISTINCT no_space_comment) AS unique_comments
    FROM RecursiveStringProcessing
)
SELECT 
    r_name as region_name,
    a.total_parts,
    a.avg_length,
    a.unique_comments,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(c.c_acctbal) AS avg_customer_balance
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN AggregatedData a ON a.total_parts > 5
GROUP BY r_name, a.total_parts, a.avg_length, a.unique_comments
ORDER BY r_name;
