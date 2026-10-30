WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        r.r_regionkey,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 5
    GROUP BY 
        r.r_name, r.r_regionkey
)
SELECT 
    r.r_name,
    ts.supplier_count,
    ts.total_acctbal,
    (SELECT COUNT(DISTINCT c.c_custkey)
     FROM customer c
     JOIN orders o ON c.c_custkey = o.o_custkey
     WHERE o.o_orderstatus = 'O') AS total_customers
FROM 
    region r
JOIN 
    TopSuppliers ts ON r.r_regionkey = ts.r_regionkey
ORDER BY 
    total_acctbal DESC;
