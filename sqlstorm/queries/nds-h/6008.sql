
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
HighlyRankedSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.total_supply_cost
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supply_rank <= 3
)
SELECT 
    h.region_name,
    COUNT(*) AS supplier_count,
    AVG(h.total_supply_cost) AS avg_total_supply_cost
FROM 
    HighlyRankedSuppliers h
GROUP BY 
    h.region_name
ORDER BY 
    supplier_count DESC, avg_total_supply_cost DESC;
