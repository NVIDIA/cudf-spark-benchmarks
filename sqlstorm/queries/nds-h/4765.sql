WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
top_suppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        ranked_suppliers rs
    WHERE 
        rs.rn <= 3
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
order_line_details AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
aggregated_orders AS (
    SELECT 
        ol.o_orderkey,
        SUM(ol.net_price) AS total_net_price,
        COUNT(DISTINCT ol.l_partkey) AS item_count
    FROM 
        order_line_details ol
    GROUP BY 
        ol.o_orderkey
)
SELECT 
    c.c_name,
    c.order_count,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(SUM(a.total_net_price), 0) AS total_order_value,
    (SELECT COUNT(*) FROM top_suppliers ts WHERE ts.total_cost > 10000) AS high_cost_suppliers_count
FROM 
    customer_orders c
LEFT JOIN 
    aggregated_orders a ON c.c_custkey = a.o_orderkey
GROUP BY 
    c.c_custkey, c.c_name, c.order_count, c.total_spent
HAVING 
    COALESCE(c.total_spent, 0) > 5000 OR COALESCE(SUM(a.total_net_price), 0) > 10000
ORDER BY 
    c.total_spent DESC, total_order_value DESC;
