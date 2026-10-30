
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_nation
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), HighValueSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name,
        rs.s_nationkey
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank_by_nation = 1 
        AND rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Has Orders'
        ELSE 'No Orders' 
    END AS order_status
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey 
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    HighValueSuppliers hvs ON hvs.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_sales DESC;
