
WITH RecursiveCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ws_total_sales.ws_total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(ws_total_sales.ws_total_sales, 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_net_paid_inc_tax) AS ws_total_sales
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) ws_total_sales ON c.c_customer_sk = ws_total_sales.ws_bill_customer_sk
),
RecurrenceCTE AS (
    SELECT 
        ca.ca_city,
        cd.cd_gender,
        SUM(rs.total_sales) AS city_sales
    FROM RecursiveCustomerSales rs
    JOIN customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
    JOIN customer_address ca ON rs.c_customer_sk = ca.ca_address_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY ca.ca_city, cd.cd_gender
    HAVING SUM(rs.total_sales) > (
        SELECT AVG(total_sales)
        FROM RecursiveCustomerSales
    )
)
SELECT 
    r.city_sales,
    r.ca_city,
    COALESCE(NULLIF(r.cd_gender, ''), 'Unknown') AS gender_label,
    COUNT(DISTINCT rs.c_customer_sk) AS num_customers,
    MAX(r.city_sales) OVER (PARTITION BY r.ca_city) AS max_city_sales,
    LEAD(r.city_sales) OVER (PARTITION BY r.ca_city ORDER BY r.city_sales DESC) AS next_city_sales
FROM RecurrenceCTE r
LEFT JOIN RecursiveCustomerSales rs ON r.ca_city = rs.c_first_name
WHERE r.cd_gender != 'M' OR r.cd_gender IS NULL
GROUP BY r.city_sales, r.ca_city, r.cd_gender
ORDER BY r.city_sales DESC
LIMIT 100;
