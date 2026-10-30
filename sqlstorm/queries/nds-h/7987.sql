WITH CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
SupplierStats AS (
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
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerStats cs
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierStats ss
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_spent AS customer_spent,
    ts.s_name AS top_supplier,
    ts.total_supply_cost AS supplier_cost
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON tc.order_count > 5 AND ts.total_supply_cost > 10000
WHERE 
    tc.spending_rank <= 5 AND ts.supply_rank <= 5
ORDER BY 
    tc.total_spent DESC, ts.total_supply_cost DESC;
