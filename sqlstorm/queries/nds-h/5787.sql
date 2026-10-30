
WITH SupplierOrderCounts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        soc.order_count
    FROM 
        SupplierOrderCounts soc
    JOIN 
        supplier s ON soc.s_suppkey = s.s_suppkey
    ORDER BY 
        soc.order_count DESC
    LIMIT 10
), 
PartStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ts.s_name, 
    p.p_name, 
    p.total_revenue
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    PartStats p ON ps.ps_partkey = p.p_partkey
ORDER BY 
    p.total_revenue DESC, 
    ts.s_name ASC;
