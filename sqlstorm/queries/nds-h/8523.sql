WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cust.c_custkey, 
        cust.c_name, 
        cust.total_order_value, 
        RANK() OVER (ORDER BY cust.total_order_value DESC) as order_rank
    FROM 
        CustomerOrders cust
)
SELECT 
    r.s_name AS Supplier_Name,
    r.total_supply_cost AS Supplier_Total_Cost,
    tc.c_name AS Top_Customer_Name,
    tc.total_order_value AS Top_Customer_Value
FROM 
    RankedSuppliers r
JOIN 
    TopCustomers tc ON r.rank = 1
ORDER BY 
    r.total_supply_cost DESC, 
    tc.total_order_value DESC;
