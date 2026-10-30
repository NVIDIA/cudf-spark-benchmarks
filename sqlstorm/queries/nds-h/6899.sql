WITH SupplierCost AS (
    SELECT ps_suppkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_suppkey
),
CustomerOrders AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count, SUM(o_totalprice) AS total_spent
    FROM orders
    GROUP BY o_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.total_cost
    FROM supplier s
    JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    cr.r_name AS customer_region,
    COUNT(oo.order_count) AS total_orders,
    SUM(oo.total_spent) AS spent_total,
    ts.s_name AS top_supplier_name,
    ts.total_cost AS top_supplier_cost
FROM 
    customer c
JOIN 
    CustomerOrders oo ON c.c_custkey = oo.o_custkey
JOIN 
    NationRegion cr ON c.c_nationkey = cr.n_nationkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 0 ORDER BY ps_supplycost ASC LIMIT 1)
WHERE 
    oo.order_count > 5
GROUP BY 
    c.c_custkey, c.c_name, cr.r_name, ts.s_name, ts.total_cost
HAVING 
    SUM(oo.total_spent) > 5000
ORDER BY 
    total_orders DESC, spent_total DESC;
