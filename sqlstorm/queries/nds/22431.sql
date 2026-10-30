
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count,
        SUM(ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_dep_count AS STRING)
        END AS dep_count,
        COALESCE(SUM(ss.ss_net_profit) FILTER (WHERE ss.ss_customer_sk IS NOT NULL), 0) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_dep_count
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.dep_count,
        COALESCE(sd.total_sales, 0) AS total_sales,
        ci.total_profit,
        sd.sales_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
    WHERE 
        (ci.total_profit > 1000 OR ci.cd_gender = 'F') 
        AND sd.sales_rank <= 5
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.dep_count,
    fr.total_sales,
    fr.total_profit,
    CASE 
        WHEN fr.total_sales > 1000 THEN 'High Seller'
        WHEN fr.total_sales BETWEEN 500 AND 999 THEN 'Average Seller'
        ELSE 'Low Seller'
    END AS seller_category,
    NULLIF(fr.total_sales, fr.total_profit) AS profit_loss_difference
FROM 
    final_report fr
ORDER BY 
    fr.total_sales DESC, fr.c_customer_sk
LIMIT 50;
