WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COALESCE(SUM(CASE WHEN cs.order_count > 0 THEN cs.total_spent ELSE 0 END), 0) AS total_revenue,
    COALESCE(SUM(rs.total_supply_value), 0) AS total_supplier_value
FROM 
    nation n
LEFT JOIN 
    CustomerOrders cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rank <= 5
GROUP BY 
    n.n_name
ORDER BY 
    total_customers DESC, total_revenue DESC;
