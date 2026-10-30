
WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER(PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
high_supply_cost_suppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name,
        rs.total_supply_cost
    FROM 
        ranked_suppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 10
),
supplier_customer_summary AS (
    SELECT 
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        c.total_spent,
        s.total_supply_cost
    FROM 
        high_supply_cost_suppliers s
    CROSS JOIN 
        customer_orders c
)
SELECT 
    s.supplier_name,
    s.customer_name,
    s.total_spent,
    s.total_supply_cost,
    s.total_spent / NULLIF(s.total_supply_cost, 0) AS spent_to_supply_ratio
FROM 
    supplier_customer_summary s
ORDER BY 
    spent_to_supply_ratio DESC;
