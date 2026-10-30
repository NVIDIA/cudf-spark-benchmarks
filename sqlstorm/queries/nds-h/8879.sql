
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    cs.c_custkey,
    cs.c_name,
    cs.total_order_value,
    cs.order_count,
    rs.s_suppkey,
    rs.s_name,
    rs.total_supply_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    CustomerOrders cs ON cs.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
WHERE 
    cs.total_order_value > 10000
ORDER BY 
    region_name, nation_name, total_order_value DESC, rs.supplier_rank
LIMIT 50;
