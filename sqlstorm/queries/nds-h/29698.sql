WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.name_length, 
        rp.p_brand, 
        rp.p_type, 
        rp.supplier_count, 
        rp.total_available_quantity, 
        rp.total_supply_cost,
        CONCAT('Brand: ', rp.p_brand, ', Type: ', rp.p_type) AS brand_type_description
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5 AND rp.brand_rank <= 3
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.name_length,
    fp.brand_type_description,
    fp.total_available_quantity,
    fp.total_supply_cost
FROM 
    FilteredParts fp
ORDER BY 
    fp.total_supply_cost DESC
LIMIT 10;
