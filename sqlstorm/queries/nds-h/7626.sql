WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
TopSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM 
        SupplierSummary s
)
SELECT 
    t.rank,
    t.s_suppkey,
    t.s_name,
    t.nation,
    t.total_parts,
    t.total_supply_cost,
    t.total_available_qty
FROM 
    TopSuppliers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_supply_cost DESC;
