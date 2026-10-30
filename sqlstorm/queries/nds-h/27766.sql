WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        sp.num_parts,
        sp.total_available_quantity,
        sp.total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON sp.num_parts > 0
) 
SELECT 
    pd.p_name, 
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_retailprice,
    TRIM(pd.p_comment) AS trimmed_comment,
    CONCAT('Supplier Count: ', COALESCE(CAST(pd.num_parts AS STRING), '0')) AS supplier_info,
    CASE 
        WHEN pd.total_supply_cost > 10000 THEN 'High Supply Cost'
        ELSE 'Standard Supply Cost'
    END AS supply_cost_category
FROM 
    PartDetails pd
WHERE 
    pd.p_mfgr LIKE '%Manufacturer%'
    AND pd.p_retailprice BETWEEN 10 AND 100
ORDER BY 
    pd.p_retailprice DESC
LIMIT 10;
