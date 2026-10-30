WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_custkey, 
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
)
SELECT 
    r.r_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    COUNT(DISTINCT s.s_suppkey) AS suppliers_count
FROM 
    lineitem l
JOIN 
    RecentOrders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.c_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND
    s.s_suppkey IN (SELECT s_suppkey FROM TopSuppliers)
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;