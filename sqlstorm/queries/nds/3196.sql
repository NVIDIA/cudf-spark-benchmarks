
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
    COALESCE(ss.total_quantity, 0) AS total_store_quantity,
    COALESCE(ss.total_profit, 0) AS total_store_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    StoreSalesData ss ON rs.ws_item_sk = ss.ss_item_sk
WHERE 
    ci.cd_purchase_estimate > 100 AND 
    (ci.cd_gender = 'M' OR ci.cd_marital_status = 'S')
GROUP BY 
    ci.c_first_name, ci.c_last_name, rs.ws_item_sk, ss.total_quantity, ss.total_profit
ORDER BY 
    total_sales_value DESC
LIMIT 10;
