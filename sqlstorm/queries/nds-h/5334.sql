WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) AS top_supplier_count,
        AVG(rs.total_supply_cost) AS avg_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supply_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    ts.region_name,
    ts.top_supplier_count,
    ts.avg_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.avg_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
ORDER BY 
    ts.top_supplier_count DESC,
    ts.avg_supply_cost DESC;
