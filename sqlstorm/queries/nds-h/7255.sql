
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        AVG(rs.total_supply_cost) AS average_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.n_nationkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    supplier_count,
    average_supply_cost
FROM 
    TopSuppliers
ORDER BY 
    supplier_count DESC, average_supply_cost DESC;
