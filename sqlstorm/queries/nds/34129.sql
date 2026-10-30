
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
customer_degrees AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(*) AS family_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    cd.family_count,
    cd.female_count,
    cd.male_count
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
JOIN 
    customer_degrees cd ON hvc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.family_count > 2 AND 
    hvc.total_sales > 10000
ORDER BY 
    hvc.total_sales DESC
LIMIT 5;
