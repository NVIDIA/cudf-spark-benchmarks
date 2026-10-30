WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
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
        rs.total_supplycost,
        RANK() OVER (ORDER BY rs.total_supplycost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    t.s_name AS supplier_name,
    t.total_supplycost,
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    t.supplier_rank <= 10
GROUP BY 
    c.c_name, c.c_address, t.s_name, t.total_supplycost, p.p_name
ORDER BY 
    t.total_supplycost DESC, c.c_name;
