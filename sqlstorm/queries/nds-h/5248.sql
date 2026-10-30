WITH SupplierPartCount AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        spc.part_count
    FROM 
        SupplierPartCount spc
    JOIN 
        supplier s ON spc.s_suppkey = s.s_suppkey
    WHERE 
        spc.part_count > 10
    ORDER BY 
        spc.part_count DESC
    LIMIT 5
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)

SELECT 
    ns.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(od.revenue) AS total_revenue
FROM 
    nation ns
JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON s.s_suppkey = c.c_nationkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN 
    OrderDetails od ON od.o_orderkey = c.c_custkey
WHERE 
    p.p_type LIKE 'SMALL%'
GROUP BY 
    ns.n_name
ORDER BY 
    total_revenue DESC, customer_count DESC;
