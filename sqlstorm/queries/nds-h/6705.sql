WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
PopularSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.part_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)

SELECT 
    ps.s_suppkey,
    ps.s_name,
    ps.total_supply_cost,
    ps.part_count,
    n.n_name,
    r.r_name
FROM 
    PopularSuppliers ps
JOIN 
    supplier s ON ps.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ps.part_count BETWEEN 5 AND 15
ORDER BY 
    ps.total_supply_cost DESC, ps.part_count ASC
LIMIT 10;
