WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
), RankedSales AS (
    SELECT
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), CustomerOrders AS (
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
)

SELECT 
    cus.c_name,
    COALESCE(sales.total_sales, 0) AS region_sales,
    cus.order_count,
    cus.total_spent,
    CASE 
        WHEN cus.total_spent > 1000 THEN 'High Value'
        WHEN cus.total_spent BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    CustomerOrders cus
LEFT JOIN 
    RankedSales sales ON sales.sales_rank = 1
WHERE 
    cus.order_count < (SELECT AVG(order_count) FROM CustomerOrders)
ORDER BY 
    cus.total_spent DESC;
