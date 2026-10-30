
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
), 
profit_summary AS (
    SELECT 
        i_item_id,
        COALESCE(SUM(ss_total_sales), 0) AS total_sales,
        COALESCE(SUM(ss_total_profit), 0) AS total_profit
    FROM (
        SELECT 
            ws_item_sk AS item_sk,
            SUM(ws_ext_sales_price) AS ss_total_sales,
            SUM(ws_net_profit) AS ss_total_profit
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
        
        UNION ALL
        
        SELECT 
            cs_item_sk AS item_sk,
            SUM(cs_ext_sales_price) AS cs_total_sales,
            SUM(cs_net_profit) AS cs_total_profit
        FROM 
            catalog_sales
        GROUP BY 
            cs_item_sk
    ) AS combined_sales
    JOIN item ON item.i_item_sk = combined_sales.item_sk
    GROUP BY 
        i_item_id
)
SELECT 
    ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ps.total_sales) AS overall_sales,
    SUM(ps.total_profit) AS overall_profit
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    profit_summary ps ON ps.total_sales > 0
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
AND 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
AND 
    cd.cd_purchase_estimate BETWEEN 100 AND 1000
GROUP BY 
    ca_state
ORDER BY 
    overall_sales DESC
LIMIT 10;
