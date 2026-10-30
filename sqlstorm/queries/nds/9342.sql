
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        c.c_current_cdemo_sk IN (
            SELECT cd_demo_sk 
            FROM customer_demographics 
            WHERE cd_gender = 'F' AND cd_marital_status = 'M'
        )
    GROUP BY
        c.c_customer_sk
),
SalesSummary AS (
    SELECT
        CASE
            WHEN total_sales < 100 THEN 'Low Value'
            WHEN total_sales >= 100 AND total_sales < 500 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value,
        COUNT(*) AS customer_count,
        AVG(order_count) AS avg_orders
    FROM
        CustomerSales
    GROUP BY
        CASE
            WHEN total_sales < 100 THEN 'Low Value'
            WHEN total_sales >= 100 AND total_sales < 500 THEN 'Medium Value'
            ELSE 'High Value'
        END
)
SELECT
    s.customer_value,
    s.customer_count,
    s.avg_orders,
    COUNT(DISTINCT cs.c_customer_sk) AS active_customers
FROM
    SalesSummary s
JOIN
    CustomerSales cs ON s.customer_value = 
        CASE 
            WHEN cs.total_sales < 100 THEN 'Low Value'
            WHEN cs.total_sales >= 100 AND cs.total_sales < 500 THEN 'Medium Value'
            ELSE 'High Value'
        END
GROUP BY
    s.customer_value, s.customer_count, s.avg_orders
ORDER BY
    s.customer_value;
