
WITH RegionSupplier AS (
    SELECT 
        r.r_name AS region_name, 
        s.s_name AS supplier_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value_supplied
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        region_name, 
        supplier_name, 
        total_parts_supplied, 
        total_value_supplied
    FROM 
        RegionSupplier
    WHERE 
        total_value_supplied > (
            SELECT 
                AVG(total_value_supplied) 
            FROM 
                RegionSupplier
        )
)
SELECT 
    region_name, 
    supplier_name, 
    total_parts_supplied, 
    total_value_supplied,
    CONCAT('Supplier ', supplier_name, ' from ', region_name, ' has supplied ', total_parts_supplied, ' parts with a total value of ', CAST(total_value_supplied AS STRING), '.') AS supplier_summary
FROM 
    HighValueSuppliers
ORDER BY 
    total_value_supplied DESC;
