WITH RankedParts AS (
    SELECT 
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        p.p_comment, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_mfgr, p.p_type, p.p_comment
), FilteredParts AS (
    SELECT 
        rp.p_name, 
        rp.p_type, 
        rp.supplier_count, 
        LENGTH(rp.p_comment) AS comment_length
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
)
SELECT 
    fp.p_type, 
    AVG(fp.comment_length) AS avg_comment_length, 
    SUM(fp.supplier_count) AS total_suppliers
FROM 
    FilteredParts fp
GROUP BY 
    fp.p_type
ORDER BY 
    avg_comment_length DESC;
