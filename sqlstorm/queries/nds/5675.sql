
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_sales < 1000 THEN 'Low'
            WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS sales_category,
        COUNT(*) AS customer_count,
        AVG(order_count) AS avg_orders,
        MAX(last_purchase_date) AS most_recent_purchase
    FROM 
        CustomerSales
    GROUP BY 
        sales_category
)
SELECT 
    ss.sales_category,
    ss.customer_count,
    ss.avg_orders,
    ss.most_recent_purchase,
    d.d_year
FROM 
    SalesSummary ss
CROSS JOIN 
    (SELECT DISTINCT d_year FROM date_dim) d
ORDER BY 
    ss.sales_category, 
    d.d_year DESC;
