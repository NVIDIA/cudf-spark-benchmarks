WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY LENGTH(p.p_name) DESC) AS rank_type
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.name_length,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_type <= 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.name_length,
    fp.supplier_count,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name
FROM 
    FilteredParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    fp.supplier_count > 1
ORDER BY 
    fp.name_length DESC, fp.supplier_count DESC
LIMIT 10;
