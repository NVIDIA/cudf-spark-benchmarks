
WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
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
    n.n_name AS nation_name, 
    r.r_name AS region_name,
    c.c_name AS customer_name, 
    co.total_orders,
    co.total_spent,
    COUNT(DISTINCT l.l_orderkey) AS unique_orders_count,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS avg_returned_amount,
    sc.total_cost AS supplier_total_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCost sc ON sc.s_suppkey = l.l_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = c.c_custkey
WHERE 
    co.total_spent > 1000 AND 
    (r.r_name IS NOT NULL OR n.n_name IS NULL)
GROUP BY 
    n.n_name, r.r_name, c.c_name, co.total_orders, co.total_spent, sc.total_cost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    co.total_spent DESC, unique_orders_count ASC;
