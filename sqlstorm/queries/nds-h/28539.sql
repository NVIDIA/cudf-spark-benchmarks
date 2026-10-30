WITH StringAggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_name, ' ', p.p_comment) AS full_description,
        LENGTH(CONCAT(p.p_name, ' ', p.p_comment)) AS total_length,
        UPPER(p.p_name) AS upper_case_name,
        LOWER(p.p_comment) AS lower_case_comment,
        REPLACE(p.p_comment, 'special', 'common') AS modified_comment
    FROM 
        part p 
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
RankedItems AS (
    SELECT 
        s.s_name,
        sa.p_partkey,
        sa.full_description,
        sa.total_length,
        ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY sa.total_length DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        StringAggregates sa ON ps.ps_partkey = sa.p_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ri.p_partkey) AS unique_parts,
    MAX(ri.total_length) AS max_length,
    MIN(ri.total_length) AS min_length,
    AVG(ri.total_length) AS avg_length
FROM 
    RankedItems ri
JOIN 
    supplier s ON ri.s_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ri.rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
