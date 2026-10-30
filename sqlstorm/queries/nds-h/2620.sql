WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails sd
),
FilteredCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        CASE 
            WHEN co.total_spent > 10000 THEN 'High Value'
            WHEN co.total_spent > 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        CustomerOrders co
    WHERE 
        co.total_orders > 1
)
SELECT 
    fc.c_name,
    fc.total_orders,
    fc.total_spent,
    fc.customer_segment,
    ts.s_name AS top_supplier
FROM 
    FilteredCustomers fc
LEFT JOIN 
    TopSuppliers ts ON fc.total_spent > ts.total_supply_cost
WHERE 
    ts.rank <= 5 OR ts.s_name IS NULL
ORDER BY 
    fc.total_spent DESC, fc.c_name ASC
LIMIT 10 OFFSET 0;
