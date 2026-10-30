WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    SUM(co.total_spent) AS region_spending,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    MAX(rs.total_cost) AS top_supplier_cost
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_custkey
JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey
WHERE 
    rs.cost_rank = 1
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    region_spending DESC, customer_count DESC;
