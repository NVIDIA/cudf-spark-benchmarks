WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE NULL END) AS avg_supply_cost
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        DENSE_RANK() OVER (ORDER BY total_available_quantity DESC) AS supplier_rank
    FROM 
        SupplierSummary s
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
)
SELECT 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN 
    TopCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, c.c_name
ORDER BY 
    revenue DESC 
LIMIT 10;