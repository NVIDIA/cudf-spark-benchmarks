
WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        s.s_name AS supplier_name,
        s.s_acctbal, 
        ps.ps_availqty,
        ps.ps_supplycost, 
        CONCAT(p.p_name, ' - ', p.p_brand, ' (', s.s_name, ')') AS detailed_description
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
SupplierStats AS (
    SELECT 
        supplier_name, 
        COUNT(p_partkey) AS total_parts, 
        SUM(ps_availqty) AS total_available_quantity, 
        AVG(ps_supplycost) AS average_supply_cost
    FROM 
        PartSupplierDetails
    GROUP BY 
        supplier_name
)
SELECT 
    s.supplier_name, 
    s.total_parts, 
    s.total_available_quantity, 
    s.average_supply_cost, 
    MAX(d.detailed_description) AS max_description
FROM 
    SupplierStats s
JOIN 
    PartSupplierDetails d ON s.supplier_name = d.supplier_name
WHERE 
    s.total_available_quantity > 100
GROUP BY 
    s.supplier_name, 
    s.total_parts, 
    s.total_available_quantity, 
    s.average_supply_cost
ORDER BY 
    s.average_supply_cost DESC, 
    s.total_parts ASC;
