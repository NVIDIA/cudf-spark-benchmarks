WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        CASE 
            WHEN LENGTH(p.p_name) <= 20 THEN 'Short Name'
            WHEN LENGTH(p.p_name) BETWEEN 21 AND 40 THEN 'Medium Name'
            ELSE 'Long Name'
        END AS name_length_category,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
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
        rp.p_brand,
        rp.p_type,
        rp.name_length_category,
        rp.supplier_count,
        rp.total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY rp.name_length_category ORDER BY rp.total_supply_cost DESC) AS rank
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.p_type,
    f.name_length_category,
    f.supplier_count,
    f.total_supply_cost
FROM 
    FilteredParts f
WHERE 
    f.rank <= 10
ORDER BY 
    f.name_length_category, f.total_supply_cost DESC;
