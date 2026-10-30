
WITH AvgOrderAmount AS (
    SELECT 
        o_custkey,
        AVG(o_totalprice) AS avg_totalprice
    FROM 
        orders
    GROUP BY 
        o_custkey
),
TopSuppliers AS (
    SELECT 
        ps_suppkey,
        SUM(ps_supplycost * ps_availqty) AS total_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_suppkey
    HAVING 
        SUM(ps_supplycost * ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey, 
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_custkey AS custkey,
    c.c_name,
    COALESCE(oa.avg_totalprice, 0) AS avg_order_amount,
    COALESCE(o.max_order_price, 0) AS max_order_value,
    sr.r_name AS supplier_region,
    CASE 
        WHEN o.order_count > 10 THEN 'High Value Customer'
        WHEN o.order_count BETWEEN 5 AND 10 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    customer c
LEFT JOIN 
    AvgOrderAmount oa ON c.c_custkey = oa.o_custkey
LEFT JOIN 
    CustomerOrders o ON c.c_custkey = o.c_custkey
LEFT JOIN 
    TopSuppliers ts ON o.c_custkey = ts.ps_suppkey
LEFT JOIN 
    SupplierRegion sr ON ts.ps_suppkey = sr.s_suppkey
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    avg_order_amount DESC, 
    max_order_value DESC;
