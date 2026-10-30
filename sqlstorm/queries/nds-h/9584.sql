WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS num_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_available_qty,
        sp.total_supply_cost,
        sp.num_parts_supplied,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.num_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    ts.s_name AS supplier_name,
    ts.total_available_qty,
    ts.total_supply_cost,
    tc.c_name AS customer_name,
    tc.total_spent,
    ts.supplier_rank,
    tc.customer_rank
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.num_parts_supplied > 5
WHERE 
    ts.supplier_rank <= 10 AND tc.customer_rank <= 10
ORDER BY 
    ts.supplier_rank, tc.customer_rank;