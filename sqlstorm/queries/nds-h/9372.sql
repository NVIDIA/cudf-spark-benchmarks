WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
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
        s.*,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank_by_cost
    FROM 
        SupplierStats s
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_supply_cost,
    t.total_parts_supplied,
    r.r_name AS supplier_region
FROM 
    TopSuppliers t
JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.rank_by_cost <= 10 
ORDER BY 
    t.total_supply_cost DESC;
