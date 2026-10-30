WITH Total_Sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ts.total_spent,
        RANK() OVER (ORDER BY ts.total_spent DESC) AS rank
    FROM 
        Total_Sales ts
    JOIN 
        customer c ON ts.c_custkey = c.c_custkey
),
Supplier_Analysis AS (
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
Top_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sa.total_supply_cost,
        RANK() OVER (ORDER BY sa.total_supply_cost DESC) AS rank
    FROM 
        Supplier_Analysis sa
    JOIN 
        supplier s ON sa.s_suppkey = s.s_suppkey
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_spent AS customer_total_spent,
    ts.s_name AS top_supplier,
    ts.total_supply_cost AS supplier_total_cost
FROM 
    Top_Customers tc
JOIN 
    Top_Suppliers ts ON tc.rank = 1 AND ts.rank = 1
WHERE 
    tc.total_spent > 10000 AND ts.total_supply_cost < 50000
ORDER BY 
    tc.total_spent DESC, ts.total_supply_cost ASC;
