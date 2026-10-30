
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_brand = 'Brand#23'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    rs.s_name AS top_supplier,
    cs.c_name AS best_customer,
    rs.total_supply_cost,
    cs.avg_order_value,
    cs.order_count
FROM 
    RankedSuppliers rs
JOIN 
    region r ON rs.s_nationkey = r.r_regionkey
JOIN 
    CustomerOrderStats cs ON rs.s_nationkey = cs.c_custkey
WHERE 
    rs.supplier_rank = 1 
    AND cs.order_count > 5
ORDER BY 
    rs.total_supply_cost DESC, 
    cs.avg_order_value DESC
LIMIT 10;
