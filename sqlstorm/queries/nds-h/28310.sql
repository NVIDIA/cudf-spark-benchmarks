WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 15) AS part_short_comment,
        COUNT(*) AS total_supplied_parts,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name, p.p_comment
),
CustomerRegions AS (
    SELECT 
        c.c_name AS customer_name,
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, r.r_name
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.part_short_comment,
    sp.total_supplied_parts,
    sp.total_available_qty,
    cr.customer_name,
    cr.region_name,
    cr.total_orders
FROM 
    SupplierParts sp
JOIN 
    CustomerRegions cr ON sp.total_available_qty > cr.total_orders
WHERE 
    sp.part_short_comment LIKE '%fragile%'
ORDER BY 
    sp.total_supplied_parts DESC, cr.total_orders ASC
LIMIT 10;
