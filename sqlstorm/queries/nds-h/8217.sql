WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT 
        nation_name,
        s.s_name,
        total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.supplier_rank <= 5
)
SELECT 
    h.nation_name,
    COUNT(h.s_name) AS top_suppliers_count,
    AVG(h.total_supply_cost) AS avg_top_supply_cost
FROM 
    HighCostSuppliers h
GROUP BY 
    h.nation_name
ORDER BY 
    top_suppliers_count DESC, avg_top_supply_cost DESC;
