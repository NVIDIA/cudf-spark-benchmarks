
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs 
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
),
customer_details AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        (SELECT COUNT(DISTINCT ws.ws_item_sk) 
         FROM web_sales ws WHERE ws.ws_ship_customer_sk = tc.c_customer_sk) AS distinct_items,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender
    FROM 
        top_customers tc 
    LEFT JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.total_sales,
    cd.distinct_items,
    cd.gender,
    COALESCE(cc.cc_name, 'No Active Call Center') AS call_center_name
FROM 
    customer_details cd
LEFT JOIN 
    call_center cc ON cd.c_customer_sk = cc.cc_call_center_sk
WHERE 
    cd.total_sales > 1000
ORDER BY 
    cd.total_sales DESC;

