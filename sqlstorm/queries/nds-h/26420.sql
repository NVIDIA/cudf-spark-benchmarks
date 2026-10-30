WITH SupplierProduct AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS product_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        supplier_name, 
        product_name, 
        available_quantity, 
        supply_cost 
    FROM 
        SupplierProduct 
    WHERE 
        rn <= 5
),
RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        fs.supplier_name,
        COUNT(fs.product_name) AS product_count,
        SUM(fs.available_quantity) AS total_available_quantity,
        SUM(fs.supply_cost) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        FilteredSuppliers fs ON s.s_name = fs.supplier_name
    GROUP BY 
        r.r_name, fs.supplier_name
)
SELECT 
    region_name,
    supplier_name,
    product_count,
    total_available_quantity,
    total_supply_cost,
    CONCAT('Supplier ', supplier_name, ' in region ', region_name, ' offers ', product_count, ' products with total availability of ', total_available_quantity, ' and a total supply cost of ', total_supply_cost) AS summary
FROM 
    RegionSupplier
ORDER BY 
    region_name, supplier_name;
