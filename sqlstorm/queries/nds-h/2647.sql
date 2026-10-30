WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps_availqty > 0
),
CustomerOrderInfo AS (
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
),
SupplierOrders AS (
    SELECT 
        su.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    JOIN 
        supplier su ON li.l_suppkey = su.s_suppkey
    GROUP BY 
        su.s_name
)
SELECT 
    c.c_name,
    ci.total_orders,
    ci.total_spent,
    SUM(coalesce(rs.supplier_rank, 0)) AS unique_best_suppliers,
    coalesce((SELECT AVG(total_sales) FROM SupplierOrders), 0) AS avg_supplier_sales
FROM 
    CustomerOrderInfo ci
JOIN 
    customer c ON ci.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
WHERE 
    ci.total_spent IS NOT NULL 
    AND ci.total_orders > 5
GROUP BY 
    c.c_name, ci.total_orders, ci.total_spent
HAVING 
    SUM(rs.supplier_rank) > 10
ORDER BY 
    ci.total_spent DESC;
