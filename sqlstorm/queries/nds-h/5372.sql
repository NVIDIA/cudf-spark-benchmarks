WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SelectedSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_value
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
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
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
)
SELECT 
    tc.c_name AS customer_name,
    ts.s_name AS supplier_name,
    ts.total_value AS supplier_total_value,
    tc.total_spent AS customer_total_spent
FROM 
    TopCustomers tc
JOIN 
    SelectedSuppliers ts ON tc.total_spent > 10000
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_spent DESC, ts.total_value DESC;
