WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rnk
    FROM 
        CustomerOrders co
),
TopSuppliers AS (
    SELECT 
        spd.s_suppkey,
        spd.s_name,
        spd.total_supply_cost,
        RANK() OVER (ORDER BY spd.total_supply_cost DESC) AS rnk
    FROM 
        SupplierPartDetails spd
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_spent AS customer_spending,
    ts.s_name AS top_supplier,
    ts.total_supply_cost AS supplier_costing
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    TopSuppliers ts ON tc.rnk = ts.rnk
WHERE 
    (tc.total_spent IS NOT NULL AND ts.total_supply_cost IS NOT NULL) OR
    (tc.total_spent IS NULL AND ts.total_supply_cost IS NULL)
ORDER BY 
    COALESCE(tc.total_spent, 0) DESC, 
    COALESCE(ts.total_supply_cost, 0) DESC;
