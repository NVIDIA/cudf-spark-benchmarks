WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        SUM(CASE 
                WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
                ELSE 0 
            END) AS discount_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.supplied_parts,
        sp.total_supply_value,
        RANK() OVER (ORDER BY sp.total_supply_value DESC) AS rank
    FROM 
        supplier s
    INNER JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
)
SELECT 
    t.s_name,
    t.total_supply_value,
    COALESCE(p.p_name, 'No Part') AS part_name,
    CASE 
        WHEN t.rank <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status,
    CASE 
        WHEN t.total_supply_value IS NULL THEN 'N/A'
        ELSE CONCAT('Value: ', CAST(t.total_supply_value AS STRING))
    END AS display_value
FROM 
    TopSuppliers t
LEFT JOIN 
    partsupp ps ON t.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    t.rank <= 5 OR p.p_size > 20
ORDER BY 
    t.total_supply_value DESC, 
    t.s_name;
