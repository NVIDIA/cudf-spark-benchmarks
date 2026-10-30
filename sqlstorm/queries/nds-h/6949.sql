
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.rank <= 5
)
SELECT 
    hcs.region_name, 
    hcs.s_name, 
    COUNT(o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    HighCostSuppliers hcs
LEFT JOIN 
    orders o ON hcs.s_name IN (SELECT s_name FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_supplycost > 100))
GROUP BY 
    hcs.region_name, hcs.s_name
ORDER BY 
    hcs.region_name, avg_order_value DESC;
