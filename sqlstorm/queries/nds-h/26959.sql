
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        r.r_name AS region,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, r.r_name, r.r_regionkey
),
MaxSupply AS (
    SELECT 
        region,
        MAX(total_supply_value) AS max_value
    FROM 
        RankedSuppliers
    GROUP BY 
        region
)
SELECT 
    rs.s_name,
    rs.region,
    rs.supply_count,
    rs.total_supply_value
FROM 
    RankedSuppliers rs
JOIN 
    MaxSupply ms ON rs.region = ms.region AND rs.total_supply_value = ms.max_value
ORDER BY 
    rs.region, rs.supply_count DESC;
