
WITH SupplierCart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(l.l_linenumber) AS total_lineitems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    co.c_name AS customer_name,
    COALESCE(sc.total_available_qty, 0) AS supplier_qty,
    COALESCE(co.total_orders, 0) AS orders_count,
    COALESCE(co.total_spent, 0) AS amount_spent,
    od.total_lineitem_value AS order_value,
    CASE 
        WHEN co.total_orders > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderDetails od ON co.c_custkey = od.o_orderkey
FULL OUTER JOIN 
    SupplierCart sc ON co.c_custkey = sc.s_suppkey
WHERE 
    (COALESCE(co.total_spent, 0) > 1000 OR sc.total_supply_cost IS NULL)
ORDER BY 
    customer_name ASC, supplier_qty DESC;
