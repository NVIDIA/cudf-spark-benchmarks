
WITH ProcessedData AS (
    SELECT 
        p.p_name,
        s.s_name,
        n.n_name,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS SupplierPartInfo,
        CHAR_LENGTH(p.p_comment) AS CommentLength,
        UPPER(p.p_type) AS UpperType,
        LOWER(n.n_name) AS LowerNationName
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size BETWEEN 10 AND 50 AND 
        s.s_acctbal > 1000.00
), 
AggregatedData AS (
    SELECT 
        UpperType,
        COUNT(*) AS PartsCount,
        AVG(CommentLength) AS AvgCommentLength
    FROM 
        ProcessedData
    GROUP BY 
        UpperType
)
SELECT 
    UpperType,
    PartsCount,
    AvgCommentLength,
    CASE 
        WHEN PartsCount > 10 THEN 'High Volume'
        WHEN PartsCount BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS VolumeCategory
FROM 
    AggregatedData
ORDER BY 
    AvgCommentLength DESC, 
    PartsCount DESC;
