
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        o.o_shippriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_shippriority
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.r_name AS region,
    SUM(CASE WHEN h.o_shippriority = 1 THEN h.total_value ELSE 0 END) AS high_priority_value,
    COUNT(DISTINCT h.o_orderkey) AS high_priority_order_count,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN 
    HighValueOrders h ON ps.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice LIMIT 1)
WHERE 
    h.total_value > 20000
GROUP BY 
    r.r_name
ORDER BY 
    high_priority_value DESC;
