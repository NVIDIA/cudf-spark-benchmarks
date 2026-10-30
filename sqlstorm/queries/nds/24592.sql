
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, cd.cd_gender ORDER BY c.c_first_name) AS rn
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
return_summary AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
final_report AS (
    SELECT
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        ss.total_sales,
        ss.order_count,
        rs.total_returned,
        rs.return_count,
        CASE 
            WHEN rs.total_returned IS NULL THEN 'No Returns'
            WHEN rs.total_returned > 0 THEN 'Returned Items'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        customer_data cd
        LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_sold_date_sk
        LEFT JOIN return_summary rs ON cd.c_customer_sk = rs.cr_item_sk
    WHERE 
        cd.rn = 1
)

SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.ca_city,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.order_count, 0) AS order_count,
    COALESCE(fr.total_returned, 0) AS total_returned,
    fr.return_count,
    fr.return_status,
    (CASE 
        WHEN total_sales IS NOT NULL AND total_sales > 1000 THEN 'High Value' 
        WHEN total_sales IS NULL THEN 'No Sales' 
        ELSE 'Regular Value' 
    END) AS customer_value_category
FROM 
    final_report fr
ORDER BY 
    fr.ca_city, fr.c_last_name;
