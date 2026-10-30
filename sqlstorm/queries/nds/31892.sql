
WITH  sales_data AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
top_stores AS (
    SELECT 
        sd.ss_store_sk, 
        sd.total_sales, 
        sd.sales_count,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        sales_data sd
    WHERE 
        sd.total_sales IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        cd.cd_purchase_estimate
    FROM 
        customer c
        INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
most_active_customers AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
        INNER JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.c_customer_sk
    HAVING 
        SUM(ws.ws_ext_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
final_report AS (
    SELECT 
        ts.ss_store_sk,
        ts.total_sales,
        ts.sales_count,
        mac.total_spent,
        ci.ca_city,
        ci.ca_state
    FROM 
        top_stores ts
        LEFT JOIN most_active_customers mac ON ts.ss_store_sk = mac.c_customer_sk
        LEFT JOIN customer_info ci ON mac.c_customer_sk = ci.c_customer_sk
)
SELECT 
    fr.ss_store_sk,
    fr.total_sales,
    fr.sales_count,
    COALESCE(fr.total_spent, 0) AS total_spent,
    CONCAT(fr.ca_city, ', ', fr.ca_state) AS location,
    RANK() OVER (ORDER BY fr.total_sales DESC) AS store_rank
FROM 
    final_report fr
WHERE 
    fr.total_sales > 10000
ORDER BY 
    fr.total_sales DESC, store_rank;
