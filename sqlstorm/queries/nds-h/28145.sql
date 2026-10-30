WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    fs.region_name,
    fs.s_suppkey,
    fs.s_name,
    fs.total_supply_cost,
    CONCAT('Supplier ', fs.s_name, ' in region ', fs.region_name, ' has total supply cost of ', CAST(fs.total_supply_cost AS STRING)) AS output_message
FROM 
    FilteredSuppliers fs
ORDER BY 
    fs.region_name, fs.total_supply_cost DESC;
