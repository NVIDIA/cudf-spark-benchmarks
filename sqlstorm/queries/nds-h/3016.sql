
WITH SupplierCosts AS (
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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY sc.total_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_linenumber) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
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
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    ts.s_name AS top_supplier_name,
    sc.total_cost AS top_supplier_cost,
    CASE 
        WHEN co.total_spent IS NULL THEN 'NO ORDERS'
        WHEN co.total_spent > 1000 THEN 'HIGH SPENDER'
        ELSE 'LOW SPENDER'
    END AS spender_category
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON ts.supplier_rank <= 5
LEFT JOIN 
    SupplierCosts sc ON sc.s_suppkey = ts.s_suppkey
WHERE 
    co.order_count > 0 AND 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC
LIMIT 10;
