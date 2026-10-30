
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, r.r_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.region_name,
        s.part_count,
        s.total_supply_cost,
        CASE 
            WHEN s.total_supply_cost > 10000 THEN 'High Value'
            WHEN s.total_supply_cost BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS supplier_value_category
    FROM 
        SupplierDetails s
    WHERE 
        s.part_count > 5
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.region_name,
    fs.part_count,
    fs.total_supply_cost,
    fs.supplier_value_category,
    CONCAT(fs.s_name, ' operates in ', fs.region_name, ' and has a total supply cost of $', CAST(fs.total_supply_cost AS DECIMAL(10, 2))) AS supplier_info
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.total_supply_cost DESC, fs.s_name;
