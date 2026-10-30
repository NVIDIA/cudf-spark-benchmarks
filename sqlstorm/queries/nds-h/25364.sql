
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS supplier_nation, 
        p.p_name AS part_name, 
        COUNT(ps.ps_availqty) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, p.p_name
)
SELECT 
    r.supplier_nation AS nation,
    r.part_name AS part,
    r.s_name AS supplier,
    r.s_address,
    r.supply_count,
    r.total_supply_cost
FROM 
    RankedSuppliers r
WHERE 
    r.rn <= 3
ORDER BY 
    r.supplier_nation, r.total_supply_cost DESC;
