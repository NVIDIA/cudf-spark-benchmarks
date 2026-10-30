
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' [', s.s_phone, ']') AS supplier_info,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_comment
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
)
SELECT 
    rp.s_name,
    rp.supplier_info,
    fp.p_name,
    fp.short_comment,
    fp.supplier_count
FROM 
    RankedSuppliers rp
JOIN 
    FilteredParts fp ON rp.rank <= 3
ORDER BY 
    rp.s_suppkey, fp.supplier_count DESC;
