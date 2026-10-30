
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.unique_parts_supplied,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats ss
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.unique_parts_supplied
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 5
ORDER BY 
    ts.total_supply_cost DESC;
