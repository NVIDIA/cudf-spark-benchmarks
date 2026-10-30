WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        c.c_custkey,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY rs.total_supplycost DESC) AS rank
    FROM 
        RankedSuppliers rs
    JOIN 
        customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE 
        rs.total_supplycost > (SELECT AVG(total_supplycost) FROM RankedSuppliers)
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    c.c_name,
    c.c_address,
    c.c_acctbal,
    ts.c_mktsegment
FROM 
    TopSuppliers ts
JOIN 
    customer c ON ts.c_custkey = c.c_custkey
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.c_mktsegment, ts.s_name;
