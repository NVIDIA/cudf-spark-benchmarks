
WITH recent_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS number_of_sales,
        CAST(d_date AS DATE) AS sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date >= CAST('2002-10-01' AS DATE) - INTERVAL '1 year'
    GROUP BY 
        ws_item_sk, CAST(d_date AS DATE)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
)
SELECT 
    r.sale_date,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ii.i_item_id,
    ii.i_item_desc,
    SUM(r.total_sales) AS total_sales,
    COUNT(r.number_of_sales) AS total_transactions
FROM 
    recent_sales r
JOIN 
    customer_info ci ON ci.c_customer_sk = r.ws_item_sk
JOIN 
    item_info ii ON ii.i_item_sk = r.ws_item_sk
GROUP BY 
    r.sale_date, ci.c_first_name, ci.c_last_name, ci.cd_gender, ii.i_item_id, ii.i_item_desc
ORDER BY 
    total_sales DESC
LIMIT 100;
