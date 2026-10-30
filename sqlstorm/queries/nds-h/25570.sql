WITH SupplierOverview AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_available_quantity,
        total_supply_cost,
        ROUND(total_supply_cost / NULLIF(total_available_quantity, 0), 2) AS cost_per_item
    FROM 
        SupplierOverview s
    WHERE 
        total_available_quantity > 0
    ORDER BY 
        cost_per_item DESC
    LIMIT 10
)
SELECT 
    s.s_suppkey,
    s.s_name,
    s.cost_per_item,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_suppkey = s.s_suppkey) AS total_line_items,
    (SELECT COUNT(DISTINCT o.o_orderkey) FROM orders o 
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_suppkey = s.s_suppkey) AS total_orders
FROM 
    HighValueSuppliers s
ORDER BY 
    s.cost_per_item;
