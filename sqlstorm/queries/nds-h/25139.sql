WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_brand
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        rs.total_supply_cost 
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.rank <= 3
        AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    s.s_name AS Supplier_Name, 
    COUNT(DISTINCT ps.ps_partkey) AS Parts_Supplied,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Supply_Value,
    r.r_name AS Region_Name
FROM 
    HighValueSuppliers s
JOIN 
    supplier supplier_info ON s.s_suppkey = supplier_info.s_suppkey
JOIN 
    nation n ON supplier_info.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    s.s_name, r.r_name
ORDER BY 
    Total_Supply_Value DESC;
