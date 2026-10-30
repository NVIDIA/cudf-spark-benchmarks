WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty) AS supply_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        supplier_name,
        COUNT(*) AS total_parts,
        SUM(supply_cost) AS total_supply_cost
    FROM 
        SupplierParts
    WHERE 
        available_quantity > 100
    GROUP BY 
        supplier_name
    HAVING 
        SUM(supply_cost) > 1000
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    h.total_parts,
    h.total_supply_cost
FROM 
    HighValueSuppliers h
JOIN 
    supplier s ON s.s_name = h.supplier_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    r.r_name, n.n_name;
