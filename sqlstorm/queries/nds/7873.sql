
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
),
customer_segment AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count
FROM 
    top_items ti
JOIN 
    sales_data sd ON ti.ws_item_sk = sd.ws_item_sk
JOIN 
    customer_segment cs ON sd.total_sales > 5000 AND cs.cd_purchase_estimate > 1000
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC, cs.customer_count DESC;
