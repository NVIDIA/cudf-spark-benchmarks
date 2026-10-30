
WITH SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    s.s_name AS supplier_name,
    COALESCE(sm.total_available, 0) AS available_quantity,
    COALESCE(c.total_orders, 0) AS customer_orders_count,
    COALESCE(c.total_spent, 0.00) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COALESCE(sm.total_cost, 0) DESC) AS rank_by_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierMetrics sm ON s.s_suppkey = sm.s_suppkey
LEFT JOIN 
    CustomerOrders c ON n.n_nationkey = c.c_custkey
WHERE 
    (COALESCE(sm.total_available, 0) > 0 OR COALESCE(c.total_orders, 0) > 0)
ORDER BY 
    n.n_name, rank_by_cost;
