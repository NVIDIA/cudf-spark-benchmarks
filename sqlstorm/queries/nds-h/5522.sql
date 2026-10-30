WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_supply_cost,
        sc.total_available_qty,
        RANK() OVER (ORDER BY sc.total_supply_cost DESC) AS rank
    FROM 
        SupplierCosts sc
    JOIN 
        supplier s ON sc.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.total_available_qty
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_supply_cost DESC;