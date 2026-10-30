WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_supplycost DESC) AS supply_rank
    FROM 
        RankedSuppliers
)
SELECT 
    ts.nation_name,
    ts.s_name,
    ts.parts_count,
    ts.total_supplycost
FROM 
    TopSuppliers ts
WHERE 
    ts.supply_rank <= 5
ORDER BY 
    ts.nation_name, ts.total_supplycost DESC;
