WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 
        AND d.d_moy IN (11, 12) 
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender
),
SalesSummary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_id) AS customer_count,
        SUM(total_sales) AS total_sales,
        AVG(total_sales) AS avg_sales_per_customer,
        SUM(number_of_orders) AS total_orders
    FROM CustomerSales
    GROUP BY cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    total_sales,
    avg_sales_per_customer,
    total_orders,
    CASE 
        WHEN avg_sales_per_customer >= 1000 THEN 'High Value'
        WHEN avg_sales_per_customer BETWEEN 500 AND 999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM SalesSummary
ORDER BY total_sales DESC;