
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COUNT(p.ps_partkey) AS part_count,
        SUM(p.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
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
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.part_count > 0 
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
)
SELECT 
    ts.s_name AS Supplier, 
    tc.c_name AS Customer, 
    ts.total_supply_cost AS Supplier_Cost,
    tc.total_spent AS Customer_Spent
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    TopCustomers tc ON ts.supplier_rank = tc.customer_rank
WHERE 
    ts.total_supply_cost IS NOT NULL OR tc.total_spent IS NOT NULL
ORDER BY 
    ts.total_supply_cost DESC, tc.total_spent DESC;
