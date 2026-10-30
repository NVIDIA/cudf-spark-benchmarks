
WITH  regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
highest_value_customers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_orders,
        cust.order_count,
        n.n_name AS nation_name
    FROM 
        customer_order_summary cust
    JOIN 
        (SELECT c_custkey, MAX(total_orders) AS max_orders
         FROM customer_order_summary
         GROUP BY c_custkey) max_cust ON cust.c_custkey = max_cust.c_custkey AND cust.total_orders = max_cust.max_orders
    JOIN 
        nation n ON cust.c_custkey = n.n_nationkey
)
SELECT 
    r.nation_name,
    COALESCE(SUM(c.total_orders), 0) AS total_orders_by_nation,
    COUNT(DISTINCT hv.c_custkey) AS high_value_customers,
    CASE 
        WHEN SUM(c.total_orders) IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM 
    regional_sales r
LEFT JOIN 
    highest_value_customers hv ON r.nation_name = hv.nation_name
LEFT JOIN 
    customer_order_summary c ON hv.c_custkey = c.c_custkey
GROUP BY 
    r.nation_name
ORDER BY 
    total_orders_by_nation DESC NULLS LAST;
