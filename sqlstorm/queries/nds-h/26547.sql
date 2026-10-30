WITH PartSupplierDetails AS (
    SELECT 
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN LENGTH(p.p_name) <= 30 THEN 'Short Name'
            WHEN LENGTH(p.p_name) BETWEEN 31 AND 50 THEN 'Medium Name'
            ELSE 'Long Name'
        END AS name_length_category,
        CONCAT(p.p_name, ' supplied by ', s.s_name) AS full_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionSupplierCounts AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    psd.p_name,
    psd.s_name,
    psd.ps_availqty,
    psd.ps_supplycost,
    psd.name_length_category,
    psd.full_description,
    rsc.supplier_count
FROM 
    PartSupplierDetails psd
JOIN 
    RegionSupplierCounts rsc ON (psd.s_name LIKE CONCAT('%', rsc.nation_name, '%'))
WHERE 
    psd.ps_supplycost < (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
ORDER BY 
    rsc.supplier_count DESC, psd.p_name;
