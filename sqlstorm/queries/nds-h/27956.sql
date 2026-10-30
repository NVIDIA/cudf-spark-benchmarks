WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        CASE 
            WHEN LENGTH(s.s_comment) < 50 THEN s.s_comment 
            ELSE SUBSTRING(s.s_comment FROM 1 FOR 50) || '...' 
        END AS trimmed_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        p.p_retailprice,
        CASE 
            WHEN POSITION('Fragile' IN p.p_comment) > 0 THEN 'Contains Fragile' 
            ELSE 'Non-Fragile' 
        END AS fragility_status
    FROM 
        part p
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        si.nation_name,
        pd.p_name,
        pd.fragility_status,
        CONCAT(si.s_name, ' from ', si.nation_name) AS supplier_identity
    FROM 
        partsupp ps
    JOIN 
        SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
)
SELECT 
    sp.supplier_identity, 
    sp.p_name, 
    sp.fragility_status,
    SUM(sp.ps_availqty) AS total_available_quantity,
    AVG(sp.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT sp.ps_partkey) AS total_unique_parts
FROM 
    SupplierPart sp
GROUP BY 
    sp.supplier_identity, sp.p_name, sp.fragility_status
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC;
