
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
), 
customer_segments AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
), 
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ss.total_quantity_sold,
        ss.total_net_paid
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    ORDER BY 
        ss.total_net_paid DESC
    LIMIT 10
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_net_paid,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status
FROM 
    top_items ti
LEFT JOIN 
    customer_segments cs ON cs.cd_demo_sk = (SELECT cd_demo_sk FROM customer_demographics ORDER BY cd_purchase_estimate DESC LIMIT 1)
ORDER BY 
    ti.total_net_paid DESC;
