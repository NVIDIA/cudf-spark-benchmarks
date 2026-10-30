
WITH SupplierPartCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.ps_supplycost AS supply_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierPartCosts sp ON n.n_nationkey = sp.s_suppkey
JOIN 
    HighCostSuppliers hc ON sp.s_suppkey = hc.s_suppkey
JOIN 
    CustomerOrders co ON co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
WHERE 
    sp.rn = 1
ORDER BY 
    r.r_name, n.n_name, hc.total_cost DESC, co.total_spent DESC;
