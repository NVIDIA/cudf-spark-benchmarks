
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rank <= 10
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        web_sales ws
    JOIN 
        top_customers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
sales_summary AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        sd.max_sales_price,
        sd.min_sales_price,
        COALESCE(sd.total_sales,0) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_sales
    FROM 
        sales_data sd
    LEFT JOIN 
        store_returns sr ON sd.ws_item_sk = sr.sr_item_sk
    GROUP BY
        sd.ws_item_sk, sd.total_sales, sd.order_count, sd.max_sales_price, sd.min_sales_price
)
SELECT 
    ss.ws_item_sk,
    ss.total_sales,
    ss.order_count,
    ss.max_sales_price,
    ss.min_sales_price,
    ss.net_sales,
    CASE 
        WHEN ss.net_sales > 1000 THEN 'High Performer'
        WHEN ss.net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    sales_summary ss
WHERE 
    ss.net_sales IS NOT NULL
ORDER BY 
    ss.net_sales DESC
LIMIT 20;
