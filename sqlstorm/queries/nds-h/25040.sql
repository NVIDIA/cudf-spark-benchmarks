WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.p_name,
        rs.ps_supplycost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn = 1
        AND rs.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    fs.s_name AS supplier_name,
    fs.p_name AS part_name,
    cs.c_name AS customer_name,
    cs.order_count,
    cs.total_spent
FROM 
    FilteredSuppliers fs
JOIN 
    CustomerOrderStats cs ON fs.s_suppkey = cs.c_custkey
ORDER BY 
    cs.total_spent DESC;
