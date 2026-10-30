
WITH StringParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        UPPER(SUBSTRING(p.p_mfgr, 1, 3)) AS mfgr_prefix
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 25
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        INITCAP(s.s_name) AS formatted_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_availability
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    sp.short_comment,
    sp.name_length,
    sp.mfgr_prefix,
    ss.formatted_name,
    ss.part_count,
    ss.total_availability
FROM 
    StringParts sp
JOIN 
    SupplierStats ss ON sp.p_partkey = ss.part_count
ORDER BY 
    sp.name_length DESC, sp.p_name ASC
LIMIT 100;
