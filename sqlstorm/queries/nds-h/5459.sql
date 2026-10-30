WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        spd.s_suppkey,
        spd.s_name,
        spd.total_available,
        spd.total_cost
    FROM 
        SupplierPartDetails spd
    WHERE 
        spd.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    WHERE 
        co.order_count > 5
)
SELECT 
    t.s_name AS supplier_name,
    t.total_available AS available_quantity,
    t.total_cost AS supply_cost,
    tc.c_name AS customer_name,
    tc.total_spent AS customer_spending
FROM 
    HighValueSuppliers t
JOIN 
    TopCustomers tc ON tc.total_spent > t.total_cost
ORDER BY 
    t.total_cost DESC, tc.total_spent DESC;
