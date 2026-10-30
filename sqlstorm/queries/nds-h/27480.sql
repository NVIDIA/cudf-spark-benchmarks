WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        LENGTH(s.s_name) > 10 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.part_count,
        rs.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY rs.total_supply_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    ts.part_count,
    ts.total_supply_cost,
    CONCAT('Supplier ', ts.s_name, ' has ', ts.part_count, ' parts supplied with a total cost of $', ROUND(ts.total_supply_cost, 2)) AS supplier_info
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 10
ORDER BY 
    ts.total_supply_cost DESC;
