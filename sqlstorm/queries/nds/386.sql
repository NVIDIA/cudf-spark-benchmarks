
WITH SalesPerformance AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
SalesMetrics AS (
    SELECT 
        s.sales_rank,
        CASE 
            WHEN s.total_sales > 10000 THEN 'High'
            WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        s.total_sales,
        s.total_orders,
        s.average_order_value
    FROM 
        SalesPerformance s
)

SELECT 
    sm.sales_rank,
    sm.sales_category,
    sm.total_sales,
    sm.total_orders,
    sm.average_order_value,
    COALESCE(p.p_promo_name, 'No Promotion') AS last_promotion
FROM 
    SalesMetrics sm
LEFT JOIN 
    promotion p ON sm.sales_rank = p.p_promo_sk
WHERE 
    sm.sales_category = 'High'
ORDER BY 
    sm.total_sales DESC
LIMIT 10
OFFSET 0;
