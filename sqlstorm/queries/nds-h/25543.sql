
WITH PartSupplierDetails AS (
    SELECT 
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ': ', p.p_name) AS SupplierPartName,
        CASE 
            WHEN ps.ps_supplycost < 100 THEN 'Low Cost'
            WHEN ps.ps_supplycost BETWEEN 100 AND 500 THEN 'Medium Cost'
            ELSE 'High Cost'
        END AS CostCategory
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighSupplyParts AS (
    SELECT 
        SPD.SupplierPartName,
        SPD.ps_availqty,
        SPD.CostCategory
    FROM 
        PartSupplierDetails SPD
    WHERE 
        SPD.ps_availqty > 50 
        AND SPD.CostCategory = 'Low Cost'
),
RegionSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    R.r_name AS Region,
    HSP.SupplierPartName,
    HSP.ps_availqty,
    HSP.CostCategory,
    RS.supplier_count
FROM 
    HighSupplyParts HSP
CROSS JOIN 
    RegionSuppliers RS
JOIN 
    region R ON RS.supplier_count > 0
ORDER BY 
    R.r_name, HSP.CostCategory;
