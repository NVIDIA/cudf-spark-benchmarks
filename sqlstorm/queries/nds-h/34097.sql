
WITH  revenue_over_time AS (
    SELECT 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderdate
),
supplier_totals AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
partitioned_revenue AS (
    SELECT 
        o_orderdate,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY o_orderdate) AS rn
    FROM 
        revenue_over_time
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY st.total_supply_cost DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        supplier_totals st ON s.s_suppkey = st.s_suppkey
)
SELECT 
    cr.c_custkey,
    cr.total_orders,
    cr.total_spent,
    COALESCE(pr.total_revenue, 0) AS revenue_for_order_date,
    rs.supplier_rank
FROM 
    customer_orders cr
LEFT JOIN 
    partitioned_revenue pr ON cr.total_orders = (
        SELECT COUNT(*) 
        FROM orders o 
        WHERE o.o_orderdate <= DATE '1998-10-01'
    )
LEFT JOIN 
    ranked_suppliers rs ON cr.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
WHERE 
    cr.total_orders IS NOT NULL
ORDER BY 
    cr.total_spent DESC, 
    rs.supplier_rank ASC
LIMIT 100;
