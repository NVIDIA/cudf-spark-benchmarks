WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ss.s_suppkey,
    ss.s_name,
    ss.nation,
    ss.total_available_qty,
    ss.total_supply_value,
    pp.p_partkey,
    pp.p_name,
    pp.total_quantity_sold
FROM 
    SupplierStats ss
JOIN 
    PopularParts pp ON ss.total_available_qty > 1000
ORDER BY 
    ss.total_supply_value DESC, pp.total_quantity_sold DESC;
