WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name,
        rs.total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank = 1 AND n.n_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')  
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region,
    nation,
    SUM(total_supply_value) AS total_high_value_supply
FROM 
    HighValueSuppliers
GROUP BY 
    region, nation
ORDER BY 
    total_high_value_supply DESC
LIMIT 10;