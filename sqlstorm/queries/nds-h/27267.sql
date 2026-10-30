WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_mfgr, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        CONCAT('Brand: ', p.p_brand, ', Name: ', p.p_name, ', Mfgr: ', p.p_mfgr) AS part_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr
),
top_parts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY supplier_count DESC, avg_supplycost ASC) as rank
    FROM 
        ranked_parts p
)
SELECT 
    tp.rank, 
    tp.part_description,
    tp.supplier_count,
    tp.avg_supplycost
FROM 
    top_parts tp
WHERE 
    tp.rank <= 10
ORDER BY 
    tp.rank;
