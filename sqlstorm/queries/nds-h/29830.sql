
WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS brand,
        p.p_retailprice AS retail_price,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' which costs $', CAST(p.p_retailprice AS DECIMAL(10, 2))) AS description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), RegionalSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT sp.supplier_name) AS total_suppliers,
        SUM(sp.retail_price) AS total_retail_price,
        MAX(sp.retail_price) AS max_retail_price,
        MIN(sp.retail_price) AS min_retail_price
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierParts sp ON s.s_name = sp.supplier_name
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    total_suppliers,
    total_retail_price,
    max_retail_price,
    min_retail_price,
    CONCAT('Region: ', region_name, ', Suppliers: ', total_suppliers, ', Retail Price Range: $', CAST(min_retail_price AS DECIMAL(10, 2)), ' - $', CAST(max_retail_price AS DECIMAL(10, 2))) AS summary
FROM 
    RegionalSuppliers
ORDER BY 
    total_suppliers DESC, region_name;
