WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available_qty,
        ss.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_available_qty DESC) AS rn
    FROM SupplierStats ss
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rn
    FROM CustomerOrders co
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_available_qty,
    ts.avg_supply_cost,
    tc.total_orders,
    tc.total_spent
FROM TopSuppliers ts
JOIN TopCustomers tc ON ts.rn = tc.rn
WHERE ts.rn <= 10
ORDER BY ts.total_available_qty DESC, tc.total_spent DESC;
