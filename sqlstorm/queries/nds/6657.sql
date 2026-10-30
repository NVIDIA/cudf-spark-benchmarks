
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
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
        cs.c_customer_sk,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High Value' 
            WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        CustomerSales cs
),
CustomerValueCount AS (
    SELECT 
        customer_value,
        COUNT(*) AS customer_count
    FROM 
        SalesSummary
    GROUP BY 
        customer_value
)
SELECT 
    cv.customer_value,
    cv.customer_count,
    CONCAT(ROUND((cv.customer_count * 100.0 / 
        (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL)), 2), '%') AS percentage_of_total_customers
FROM 
    CustomerValueCount cv
ORDER BY 
    CASE 
        WHEN cv.customer_value = 'High Value' THEN 1
        WHEN cv.customer_value = 'Medium Value' THEN 2
        ELSE 3 
    END;
