
WITH SupplierCostSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierCostSummary s
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderSummary c
    WHERE 
        total_spent > 1000
)

SELECT 
    c.c_name AS customer_name,
    ts.s_name AS supplier_name,
    o.o_orderkey,
    l.l_quantity,
    l.l_extendedprice,
    CASE 
        WHEN l.l_discount > 0 THEN 'Discounted'
        ELSE 'Regular'
    END AS pricing_type,
    COALESCE(sTotal.total_supply_cost, 0) AS supplier_total_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_number
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
LEFT JOIN 
    SupplierCostSummary sTotal ON ts.s_suppkey = sTotal.s_suppkey
WHERE 
    l.l_shipdate > '1996-01-01'
    AND EXISTS (
        SELECT 1 
        FROM HighSpendingCustomers h 
        WHERE h.c_custkey = c.c_custkey AND h.customer_rank <= 10
    )
ORDER BY 
    c.c_name, supplier_total_cost DESC, o.o_orderdate DESC;
