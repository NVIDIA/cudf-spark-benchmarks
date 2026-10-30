
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
item_rank AS (
    SELECT 
        i_item_sk,
        i_item_id,
        ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY i_current_price DESC) AS item_rank
    FROM 
        item
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender AS gender,
        h.hd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_purchases,
        AVG(s.ss_net_paid) AS avg_store_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics h ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        store_sales s ON s.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, h.hd_income_band_sk, cd.cd_marital_status
)
SELECT 
    s.dt,
    ss.total_sales,
    i.i_item_id,
    ci.c_customer_id,
    ci.gender,
    ci.marital_status,
    ci.total_store_purchases,
    ci.avg_store_purchase,
    CASE 
        WHEN ci.total_store_purchases IS NULL THEN 'No Purchases'
        ELSE 'Has Purchases' 
    END AS purchase_status
FROM 
    (SELECT d.d_date AS dt, d.d_date_sk FROM date_dim d WHERE d.d_year = 2022) s
LEFT JOIN 
    sales_summary ss ON s.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    item_rank i ON i.item_rank <= 10
LEFT JOIN 
    customer_info ci ON ci.total_store_purchases > 5
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC, ci.c_customer_id;
