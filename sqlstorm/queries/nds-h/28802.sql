
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        p.p_name AS part_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        POSITION('steel' IN p.p_name) > 0
)
SELECT 
    part_name, 
    STRING_AGG(CONCAT(s_name, ' (', nation_name, ') - Available Qty: ', CAST(ps_availqty AS STRING), ' - Cost: $', CAST(ps_supplycost AS DECIMAL(12,2))), '; ') AS Best_Suppliers
FROM 
    RankedSuppliers
WHERE 
    supplier_rank <= 3
GROUP BY 
    part_name
ORDER BY 
    part_name;
