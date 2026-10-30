WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY LENGTH(p.p_name) DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.comment_length
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_mfgr,
    SUBSTRING(tp.p_name, 1, 10) AS short_name,
    CONCAT(tp.p_mfgr, ' - ', tp.p_name) AS formatted_name,
    CASE 
        WHEN tp.comment_length < 30 THEN 'Short Comment'
        WHEN tp.comment_length BETWEEN 30 AND 100 THEN 'Medium Comment'
        ELSE 'Long Comment'
    END AS comment_category
FROM 
    TopParts tp
WHERE 
    tp.p_mfgr NOT LIKE 'B%'
ORDER BY 
    tp.comment_length DESC, tp.p_name ASC;
