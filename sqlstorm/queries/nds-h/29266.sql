
WITH String_Processing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CONCAT(LEFT(p.p_name, 10), '...', SUBSTRING(p.p_name, CHAR_LENGTH(p.p_name) - 9, 10)) AS abbreviated_name,
        REPLACE(REPLACE(s.s_address, 'Street', 'St'), 'Avenue', 'Ave') AS simplified_address,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        LOWER(REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '')) AS cleaned_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), Aggregated_String_Results AS (
    SELECT
        COUNT(DISTINCT p_partkey) AS unique_parts,
        AVG(comment_length) AS avg_comment_length,
        COUNT(*) FILTER (WHERE CHAR_LENGTH(cleaned_comment) > 0) AS non_empty_comments
    FROM 
        String_Processing
)
SELECT 
    u.unique_parts,
    a.avg_comment_length,
    n.non_empty_comments
FROM 
    (SELECT COUNT(DISTINCT p_partkey) AS unique_parts FROM String_Processing) u,
    (SELECT AVG(comment_length) AS avg_comment_length FROM String_Processing) a,
    (SELECT COUNT(*) AS non_empty_comments FROM String_Processing WHERE CHAR_LENGTH(cleaned_comment) > 0) n;
