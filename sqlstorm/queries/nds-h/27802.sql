WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        TRIM(UPPER(SUBSTRING(s.s_comment, 1, 20))) AS comment_snippet,
        LENGTH(s.s_comment) - LENGTH(REPLACE(s.s_comment, ' ', '')) AS word_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        AVG(ps.ps_supplycost) AS average_supplycost,
        COUNT(*) AS supply_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
)
SELECT 
    sd.s_name,
    sd.supplier_nation,
    ps.p_name,
    ps.average_supplycost,
    ps.supply_count,
    sd.word_count,
    CASE 
        WHEN sd.word_count > 5 THEN 'Long Comment'
        ELSE 'Short Comment'
    END AS comment_length_category
FROM 
    SupplierDetails sd
JOIN 
    PartStatistics ps ON sd.s_suppkey = ps.p_partkey
WHERE 
    sd.comment_snippet LIKE '%REQUIRED%'
ORDER BY 
    ps.average_supplycost DESC, sd.s_name ASC;
