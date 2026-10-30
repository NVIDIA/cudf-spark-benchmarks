WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 0
),
top_customers AS (
    SELECT 
        customer_orders.c_custkey,
        customer_orders.c_name,
        customer_orders.total_orders,
        customer_orders.total_spent,
        ROW_NUMBER() OVER (ORDER BY customer_orders.total_spent DESC) AS rank
    FROM 
        customer_orders
)
SELECT 
    top_customers.c_name,
    top_customers.total_orders,
    top_customers.total_spent,
    r.r_name AS region_name,
    s.total_supplycost
FROM 
    top_customers
JOIN 
    nation n ON top_customers.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier_info s ON s.s_nationkey = n.n_nationkey
WHERE 
    top_customers.rank <= 10 
    AND (s.total_supplycost IS NULL OR s.total_supplycost > 10000)
ORDER BY 
    top_customers.total_spent DESC;