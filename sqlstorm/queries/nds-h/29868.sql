WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' supplied by ', s.s_name) AS CombinedString,
        LENGTH(CONCAT(p.p_name, ' supplied by ', s.s_name)) AS StringLength,
        REPLACE(REPLACE(REPLACE(CONCAT(p.p_name, ' ', s.s_name), ' ', ''), 'a', ''), 'e', '') AS VowelRemoved,
        UPPER(CONCAT(p.p_name, ' ', s.s_name)) AS Uppercase,
        LOWER(CONCAT(p.p_name, ' ', s.s_name)) AS Lowercase,
        LENGTH(UPPER(CONCAT(p.p_name, ' ', s.s_name))) AS UppercaseLength,
        LENGTH(LOWER(CONCAT(p.p_name, ' ', s.s_name))) AS LowercaseLength
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_name) > 10
        AND s.s_comment LIKE '%important%'
)
SELECT 
    p_name,
    s_name,
    CombinedString,
    StringLength,
    VowelRemoved,
    Uppercase,
    Lowercase,
    UppercaseLength,
    LowercaseLength
FROM 
    StringBenchmark
ORDER BY 
    StringLength DESC,
    p_name;
