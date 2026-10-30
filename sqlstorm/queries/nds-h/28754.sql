WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS supplier_name,
    AVG(l.l_extendedprice) AS avg_extended_price,
    hvc.c_name AS high_value_customer,
    hvc.total_spent AS customer_spending
FROM 
    RankedSuppliers rs
JOIN 
    lineitem l ON rs.s_suppkey = l.l_suppkey
JOIN 
    HighValueCustomers hvc ON hvc.rank <= 5
WHERE 
    rs.rank <= 3
GROUP BY 
    rs.s_name, hvc.c_name, hvc.total_spent
ORDER BY 
    supplier_name, customer_spending DESC;
