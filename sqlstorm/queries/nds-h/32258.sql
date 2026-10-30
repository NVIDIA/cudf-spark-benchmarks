
WITH  sales_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ss.total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_custkey = ss.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(ss.total_sales) > 1000
)
SELECT 
    tc.c_name,
    COALESCE(p.p_mfgr, 'Unknown') AS manufacturer,
    COALESCE(ROUND(AVG(ps.ps_supplycost), 2), 0) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    top_customers tc
LEFT JOIN 
    orders o ON tc.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    tc.c_name, p.p_mfgr
ORDER BY 
    total_orders DESC, avg_supply_cost DESC
LIMIT 10;
