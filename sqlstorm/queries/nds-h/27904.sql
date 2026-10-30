
WITH StringPatterns AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand) AS part_branded_name,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS short_name,
        REPLACE(p.p_comment, 'good', 'excellent') AS updated_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10
), RegionCount AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    sp.p_partkey,
    sp.part_branded_name,
    sp.supplier_name,
    rc.nation_name,
    rc.supplier_count,
    sp.comment_length,
    sp.updated_comment
FROM 
    StringPatterns sp
JOIN 
    RegionCount rc ON rc.nation_name = sp.supplier_name
WHERE 
    sp.comment_length > 20
ORDER BY 
    sp.p_retailprice DESC, 
    rc.supplier_count ASC
LIMIT 100;
