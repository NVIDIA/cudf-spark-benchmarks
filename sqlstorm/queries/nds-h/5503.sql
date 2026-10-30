
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ps.ps_availqty > 0
),
AveragePrice AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.p_name,
        rs.ps_availqty,
        rs.ps_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        AveragePrice avg ON rs.p_partkey = avg.p_partkey
    WHERE 
        rs.rn <= 3 AND rs.ps_supplycost < avg.avg_supplycost
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.nation_name,
    ts.p_name,
    ts.ps_availqty,
    ts.ps_supplycost
FROM 
    TopSuppliers ts
ORDER BY 
    ts.nation_name, ts.p_name, ts.ps_supplycost DESC;
