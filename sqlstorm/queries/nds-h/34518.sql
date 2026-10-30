
WITH  Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), Supplier_Info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name AS customer_name,
    co.num_orders AS total_orders,
    ROUND(co.avg_order_value, 2) AS average_order_value,
    CASE 
        WHEN co.num_orders > 10 THEN 'High Volume'
        WHEN co.num_orders BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    si.s_name AS supplier_name,
    si.total_cost AS supplier_total_cost,
    sc.total_sales AS order_total_sales
FROM 
    Customer_Orders co
LEFT JOIN 
    Supplier_Info si ON si.total_cost = (
        SELECT 
            MAX(total_cost) 
        FROM 
            Supplier_Info
    )
LEFT JOIN 
    Sales_CTE sc ON sc.o_orderkey = (
        SELECT 
            o_orderkey 
        FROM 
            Sales_CTE 
        ORDER BY 
            total_sales DESC 
        LIMIT 1
    )
WHERE 
    co.num_orders IS NOT NULL
ORDER BY 
    co.num_orders DESC, si.total_cost DESC;
