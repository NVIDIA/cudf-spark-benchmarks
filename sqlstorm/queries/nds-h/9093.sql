WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        n.n_name,
        ss.total_supply_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierStats ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    WHERE 
        ss.part_count > 5
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.n_name,
    ts.total_supply_cost,
    ts.part_count
FROM 
    TopSuppliers ts
WHERE 
    ts.cost_rank <= 10
ORDER BY 
    ts.total_supply_cost DESC;
