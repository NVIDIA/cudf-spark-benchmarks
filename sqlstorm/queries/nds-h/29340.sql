WITH RegionSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name, s.s_name
), 
HighValueSuppliers AS (
    SELECT 
        region_name,
        supplier_name,
        part_count,
        total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        RegionSuppliers
)
SELECT 
    region_name,
    supplier_name,
    part_count,
    total_supply_cost,
    CASE 
        WHEN cost_rank = 1 THEN 'Highest Value Supplier'
        WHEN cost_rank <= 3 THEN 'Top 3 Supplier'
        ELSE 'Other Supplier'
    END AS supplier_category
FROM 
    HighValueSuppliers
WHERE 
    part_count > 5
ORDER BY 
    region_name, total_supply_cost DESC;
