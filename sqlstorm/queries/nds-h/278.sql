WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
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
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers,
    AVG(rs.total_supply_cost) AS average_supply_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = co.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
WHERE 
    (co.o_orderstatus = 'F' OR co.o_orderstatus IS NULL)
    AND (rs.rank_within_nation <= 3 OR rs.rank_within_nation IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(co.o_totalprice) > 10000.00
ORDER BY 
    total_revenue DESC;
