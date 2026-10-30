
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    cs.total_spent AS customer_spending,
    rs.total_cost AS supplier_cost,
    rs.s_name AS supplier_name
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON o.o_custkey = cs.c_custkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31' 
    AND (l.l_discount > 0.1 OR l.l_returnflag = 'R')
GROUP BY 
    n.n_name, p.p_name, cs.total_spent, rs.total_cost, rs.s_name
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 10000
ORDER BY 
    total_revenue DESC, cs.total_spent ASC;
