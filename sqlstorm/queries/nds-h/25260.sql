WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' - ', s.s_name) AS part_supplier_combo,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name)) AS combo_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), FilteredDetails AS (
    SELECT 
        p_partkey,
        part_supplier_combo,
        SUM(ps_supplycost) AS total_supply_cost,
        MAX(combo_length) AS max_combo_length
    FROM 
        PartSupplierDetails
    WHERE 
        s_acctbal > 1000.00
    GROUP BY 
        p_partkey, part_supplier_combo
)
SELECT 
    p_partkey,
    part_supplier_combo,
    total_supply_cost,
    max_combo_length
FROM 
    FilteredDetails
ORDER BY 
    total_supply_cost DESC, max_combo_length ASC
LIMIT 10;
