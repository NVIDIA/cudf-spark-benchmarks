WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    ORDER BY 
        sr.total_revenue DESC
    LIMIT 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    COUNT(o.o_orderkey) AS total_orders,
    AVG(l.l_discount) AS avg_discount,
    MAX(l.l_extendedprice) AS max_extended_price
FROM 
    TopSuppliers t
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')))
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
GROUP BY 
    t.s_suppkey, t.s_name, t.total_revenue
HAVING 
    AVG(l.l_discount) > 0.05
ORDER BY 
    total_revenue DESC;
