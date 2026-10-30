WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 20
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sp.total_cost, 
        sp.part_count,
        ROW_NUMBER() OVER (ORDER BY sp.total_cost DESC) AS rn
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_cost,
    ts.part_count,
    r.r_name AS region_name
FROM 
    TopSuppliers ts
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT MIN(o.o_custkey) FROM orders o WHERE o.o_orderkey = (SELECT MIN(l.l_orderkey) FROM lineitem l WHERE l.l_discount > 0.05)))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.rn <= 10
ORDER BY 
    ts.total_cost DESC;
