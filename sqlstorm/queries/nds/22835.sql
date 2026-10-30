
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
aggregate_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        total_sales,
        order_count,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer_sales cs
),
sales_metrics AS (
    SELECT 
        customer_value,
        AVG(total_sales) AS avg_sales,
        SUM(order_count) AS total_orders,
        COUNT(*) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY customer_value ORDER BY AVG(total_sales) DESC) AS sales_rank
    FROM aggregate_sales
    GROUP BY customer_value
)
SELECT 
    sm.customer_value,
    sm.avg_sales,
    sm.total_orders,
    sm.customer_count,
    COALESCE(NULLIF(sm.avg_sales, 0), NULL) AS avg_sales_with_null_handling,
    CASE 
        WHEN sm.customer_value IS NOT NULL THEN CONCAT('Class: ', sm.customer_value)
        ELSE 'No Class'
    END AS customer_class_info
FROM sales_metrics sm
FULL OUTER JOIN income_band ib ON (sm.avg_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
WHERE ib.ib_income_band_sk IS NULL OR sm.customer_value IS NOT NULL
ORDER BY sm.avg_sales DESC NULLS LAST;
