WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available_qty,
        ss.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_available_qty DESC) AS supplier_rank
    FROM 
        SupplierSummary ss
    WHERE 
        ss.total_available_qty > 0
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
)

SELECT 
    coi.c_custkey,
    coi.c_name,
    COALESCE(coi.total_orders, 0) AS total_orders,
    COALESCE(coi.total_spent, 0) AS total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_available_qty,
    ts.avg_supply_cost
FROM 
    CustomerOrderInfo coi
LEFT JOIN 
    TopSuppliers ts ON ts.supplier_rank = 1
WHERE 
    coi.total_spent > 10000
ORDER BY 
    coi.total_spent DESC
LIMIT 10;
