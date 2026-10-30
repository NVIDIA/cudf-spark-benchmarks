WITH OrderSummary AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
SupplierPart AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
HighlyActiveCustomers AS (
    SELECT 
        os.customer_name, 
        os.total_spent, 
        os.order_count, 
        os.first_order_date, 
        os.last_order_date
    FROM 
        OrderSummary os
    WHERE 
        os.order_count > 10 AND os.total_spent > 1000
),
SuspiciousSuppliers AS (
    SELECT 
        sp.supplier_name, 
        sp.parts_supplied, 
        sp.total_supply_cost
    FROM 
        SupplierPart sp
    WHERE 
        sp.total_supply_cost > 5000
)
SELECT 
    hac.customer_name,
    hac.total_spent,
    hac.order_count,
    hac.first_order_date,
    hac.last_order_date,
    ss.supplier_name,
    ss.parts_supplied,
    ss.total_supply_cost
FROM 
    HighlyActiveCustomers hac
JOIN 
    SuspiciousSuppliers ss ON hac.total_spent > 2000
ORDER BY 
    hac.total_spent DESC, ss.total_supply_cost DESC
LIMIT 20;
