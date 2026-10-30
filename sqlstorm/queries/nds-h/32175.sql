
WITH  CTE_Customer_Sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
CTE_Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
Total_Orders AS (
    SELECT 
        COUNT(*) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        orders o
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    cs.total_spent,
    ss.total_parts_supplied,
    ss.avg_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) >= 5 THEN 'High'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 1 AND 4 THEN 'Medium'
        ELSE 'Low'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    CTE_Customer_Sales cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    CTE_Supplier_Stats ss ON l.l_suppkey = ss.s_suppkey
GROUP BY 
    n.n_name, cs.total_spent, ss.total_parts_supplied, ss.avg_supply_cost, n.n_nationkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_spent) FROM CTE_Customer_Sales)
ORDER BY 
    revenue DESC;
