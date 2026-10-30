
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, p.p_name, n.n_regionkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation,
        COUNT(DISTINCT rs.p_name) AS unique_parts_count,
        rs.total_available_qty,
        rs.avg_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 5
    GROUP BY 
        rs.s_suppkey, rs.s_name, rs.nation, rs.total_available_qty, rs.avg_supply_cost
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.nation,
    fs.unique_parts_count,
    fs.total_available_qty,
    fs.avg_supply_cost,
    ROUND(fs.total_available_qty * fs.avg_supply_cost, 2) AS total_value
FROM 
    FilteredSuppliers fs
WHERE 
    fs.total_available_qty > 100
ORDER BY 
    total_value DESC
LIMIT 10;
