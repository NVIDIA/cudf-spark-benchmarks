WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerPurchases AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
TopSuppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_supply_value DESC) AS supplier_rank 
    FROM 
        SupplierStats s
), 
TopCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank 
    FROM 
        CustomerPurchases c
)

SELECT 
    tc.c_name AS top_customer, 
    ts.s_name AS top_supplier, 
    tc.total_spent, 
    ts.total_supply_value 
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON tc.total_orders > 5 AND ts.supplier_rank <= 10
ORDER BY 
    tc.total_spent DESC, ts.total_supply_value DESC
LIMIT 50;