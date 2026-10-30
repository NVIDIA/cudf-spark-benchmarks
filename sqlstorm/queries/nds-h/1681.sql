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

LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    c.c_name,
    COALESCE(co.order_count, 0) AS num_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(sc.total_cost, 0) AS supplier_cost,
    ls.total_revenue,
    ls.line_item_count,
    CASE 
        WHEN co.total_spent IS NULL AND sc.total_cost IS NULL THEN 'No Orders and No Supplier Cost'
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN sc.total_cost IS NULL THEN 'No Supplier Cost'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierCosts sc ON co.c_custkey = sc.s_suppkey
LEFT JOIN 
    LineItemSummary ls ON co.c_custkey = ls.l_orderkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
ORDER BY 
    total_spent DESC, num_orders DESC, supplier_cost DESC;