
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
DetailedReport AS (
    SELECT 
        tc.c_name,
        ts.parts_count,
        ts.total_supply_cost,
        ts.avg_acctbal,
        CASE 
            WHEN ts.parts_count > 5 THEN 'High Supplier'
            ELSE 'Low Supplier'
        END AS supplier_category
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierStats ts ON ts.parts_count > 0
)
SELECT 
    d.c_name,
    d.parts_count,
    d.total_supply_cost,
    d.avg_acctbal,
    d.supplier_category,
    CASE 
        WHEN d.total_supply_cost IS NULL THEN 'No supplies available'
        ELSE 'Supplies available'
    END AS supply_availability
FROM 
    DetailedReport d
WHERE 
    d.supplier_category = 'High Supplier'
ORDER BY 
    d.avg_acctbal DESC
LIMIT 10;
