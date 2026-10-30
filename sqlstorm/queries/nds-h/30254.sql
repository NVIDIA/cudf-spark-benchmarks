
WITH  top_customers AS (
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
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
supplier_performance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 1
),
final_results AS (
    SELECT 
        tc.c_name AS top_customer_name,
        sp.s_name AS supplier_name,
        tc.total_spent,
        sp.total_supply_value,
        cp.order_count,
        cp.last_order_date
    FROM 
        top_customers tc
    JOIN 
        customer_orders cp ON tc.c_custkey = cp.c_custkey
    LEFT JOIN 
        supplier_performance sp ON sp.total_avail_qty > 1000
)
SELECT 
    fr.top_customer_name,
    fr.supplier_name,
    COALESCE(fr.total_spent, 0) AS total_spent,
    COALESCE(fr.total_supply_value, 0) AS total_supply_value,
    fr.order_count,
    fr.last_order_date,
    CASE 
        WHEN fr.last_order_date IS NULL THEN 'No orders yet'
        ELSE 'Active customer'
    END AS customer_status
FROM 
    final_results fr
ORDER BY 
    fr.total_spent DESC, 
    fr.total_supply_value DESC;
