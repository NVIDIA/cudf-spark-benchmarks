
WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.total_order_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        order_summary o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(ss.total_supply_cost, 0) AS highest_suppliers_cost,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No orders'
        WHEN cs.total_spent < 5000 THEN 'Low spender'
        WHEN cs.total_spent BETWEEN 5000 AND 20000 THEN 'Medium spender'
        ELSE 'High spender'
    END AS spending_category
FROM 
    customer_summary cs
LEFT JOIN 
    supplier_summary ss ON cs.total_spent = (
        SELECT MAX(total_supply_cost) 
        FROM supplier_summary
        WHERE parts_supplied > (
            SELECT AVG(parts_supplied) 
            FROM supplier_summary
        )
    )
WHERE 
    cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC;
