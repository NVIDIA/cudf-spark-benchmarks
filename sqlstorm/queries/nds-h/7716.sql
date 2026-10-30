WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
), TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(*) AS supplier_count
    FROM 
        RankedSuppliers
    JOIN 
        nation n ON RankedSuppliers.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        RankedSuppliers.cost_rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    EXISTS (SELECT 1 FROM TopSuppliers ts WHERE ts.region_name = r.r_name)
GROUP BY 
    r.r_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
