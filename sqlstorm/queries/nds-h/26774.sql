WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_combo
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderedItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_ordered
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.supplier_name,
    rp.part_name,
    rp.available_quantity,
    rp.supply_cost,
    oi.total_revenue,
    oi.unique_parts_ordered,
    rp.supplier_part_combo  
FROM 
    SupplierParts rp
JOIN 
    OrderedItems oi ON oi.o_orderkey = rp.available_quantity
WHERE 
    rp.available_quantity > (SELECT AVG(ps_availqty) FROM partsupp)
ORDER BY 
    rp.supply_cost DESC, oi.total_revenue DESC
LIMIT 10;