WITH EnhancedStringProcessing AS (
    SELECT 
        p.p_name, 
        s.s_name, 
        CONCAT('Supplier ', s.s_name, ' provides part: ', p.p_name, 
               ' - ', p.p_comment, ' [', p.p_brand, ']') AS EnhancedDescription,
        LENGTH(CONCAT('Supplier ', s.s_name, ' provides part: ', p.p_name, 
                      ' - ', p.p_comment, ' [', p.p_brand, ']')) AS DescriptionLength,
        UPPER(SUBSTRING(p.p_comment, 1, 10)) AS CommentSnippet,
        REPLACE(LOWER(p.p_type), ' ', '-') AS ProcessedType
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00 
        AND s.s_acctbal > 500.00
    ORDER BY 
        DescriptionLength DESC 
    LIMIT 20
)
SELECT 
    COUNT(*) AS TotalRecords, 
    AVG(DescriptionLength) AS AverageDescriptionLength, 
    MAX(DescriptionLength) AS MaxDescriptionLength, 
    MIN(DescriptionLength) AS MinDescriptionLength
FROM 
    EnhancedStringProcessing;
