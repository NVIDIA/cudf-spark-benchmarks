WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TotalCostPerNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(total_supply_cost) AS avg_supply_cost,
    SUM(total_supply_cost) AS total_supply_cost_by_region
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    TotalCostPerNation tcpn ON n.n_name = tcpn.nation_name
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_cost_by_region DESC;
