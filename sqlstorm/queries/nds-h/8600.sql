WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
)

SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(l.l_orderkey) AS line_items,
    rs.total_supply_value,
    rs.supplier_rank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, rs.total_supply_value, rs.supplier_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC, line_items DESC;