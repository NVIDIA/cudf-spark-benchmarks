WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        COUNT(ps.ps_partkey) AS total_supply,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
FilteredSuppliers AS (
    SELECT 
        supplier_name,
        part_name,
        total_supply,
        total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY supplier_name ORDER BY total_supply DESC) AS rn
    FROM 
        SupplierParts
)
SELECT 
    fs.supplier_name,
    fs.part_name,
    fs.total_supply,
    fs.total_supply_cost,
    CONCAT('Supplier: ', fs.supplier_name, ' provides part: ', fs.part_name, ' with total supplies: ', fs.total_supply) AS info_message
FROM 
    FilteredSuppliers fs
WHERE 
    fs.rn <= 5
ORDER BY 
    fs.supplier_name, fs.total_supply DESC;
