
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rank_by_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), FilteredParts AS (
    SELECT 
        r.p_partkey,
        r.p_name,
        r.p_brand,
        r.supplier_count,
        r.avg_supplycost,
        r.suppliers
    FROM 
        RankedParts r
    WHERE 
        r.rank_by_suppliers <= 5
) 
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand, 
    CONCAT('Total Suppliers: ', CAST(fp.supplier_count AS STRING), ', Average Cost: ', CAST(ROUND(fp.avg_supplycost, 2) AS STRING), ', Suppliers: ', fp.suppliers) AS summary 
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_brand, fp.supplier_count DESC;
