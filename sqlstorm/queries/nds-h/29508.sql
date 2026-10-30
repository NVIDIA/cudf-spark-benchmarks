WITH StringAggregates AS (
    SELECT 
        p.p_name,
        n.n_name AS nation_name,
        CONCAT(p.p_name, ' - ', n.n_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' - ', n.n_name)) AS string_length,
        REPLACE(n.n_comment, ' ', '-') AS comment_replaced,
        SUBSTRING(n.n_comment, 1, 50) AS comment_snippet
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
AggregatedResults AS (
    SELECT
        MAX(string_length) AS max_length,
        MIN(string_length) AS min_length,
        AVG(string_length) AS avg_length,
        COUNT(*) AS total_count
    FROM 
        StringAggregates
)
SELECT 
    sa.p_name,
    sa.nation_name,
    sa.combined_string,
    sa.string_length,
    sa.comment_replaced,
    sa.comment_snippet,
    ar.max_length,
    ar.min_length,
    ar.avg_length,
    ar.total_count
FROM 
    StringAggregates sa, 
    AggregatedResults ar
ORDER BY 
    sa.string_length DESC
LIMIT 10;
