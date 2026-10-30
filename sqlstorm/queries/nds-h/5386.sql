WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        part p ON p.p_partkey = rs.s_suppkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn = 1
)
SELECT 
    region_name,
    nation_name,
    COUNT(DISTINCT supplier_name) AS supplier_count,
    SUM(total_cost) AS total_cost_sum
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    total_cost_sum DESC, region_name, nation_name;
