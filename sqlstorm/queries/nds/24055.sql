
WITH  sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
    HAVING 
        SUM(ws_net_profit) IS NOT NULL
    UNION ALL
    SELECT 
        cs_bill_customer_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk, cs_item_sk
    HAVING 
        SUM(cs_net_profit) IS NOT NULL
), ranked_sales AS (
    SELECT 
        customer.c_customer_id AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        CASE
            WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' THEN 'Married Female'
            WHEN cd.cd_marital_status = 'M' THEN 'Married Male'
            WHEN cd.cd_gender = 'F' THEN 'Single Female'
            ELSE 'Single Male'
        END AS demographic_label
    FROM 
        sales_data sd
    JOIN 
        customer ON sd.ws_bill_customer_sk = customer.c_customer_sk
    JOIN 
        customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sd.rank <= 5
)
SELECT 
    r.customer_id,
    r.demographic_label,
    COALESCE(SUM(r.total_quantity), 0) AS total_quantity_sold,
    COUNT(DISTINCT r.ws_item_sk) AS unique_items_sold,
    SUM(r.total_profit) AS total_profit_made
FROM 
    ranked_sales r
LEFT JOIN 
    store_returns sr ON r.ws_item_sk = sr.sr_item_sk AND sr.sr_return_quantity > 0
LEFT JOIN 
    web_returns wr ON r.ws_item_sk = wr.wr_item_sk AND wr.wr_return_quantity > 0
GROUP BY 
    r.customer_id, r.demographic_label
HAVING 
    SUM(r.total_profit) IS NOT NULL AND COUNT(DISTINCT r.ws_item_sk) > 0
ORDER BY 
    total_profit_made DESC, total_quantity_sold DESC
LIMIT 100;
