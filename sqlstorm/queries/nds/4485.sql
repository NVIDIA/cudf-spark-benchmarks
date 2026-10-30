
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS item_rank
    FROM 
        web_sales
), TotalSales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
), CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
), StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS store_net_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)

SELECT 
    ca.ca_state,
    COALESCE(SUM(ts.total_net_profit), 0) AS total_sales_profit,
    COALESCE(SUM(ss.store_net_profit), 0) AS total_store_profit,
    cd.cd_gender AS customer_gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    MAX(rs.ws_sales_price) AS highest_item_price,
    MIN(CASE WHEN rs.item_rank = 1 THEN rs.ws_sales_price END) AS lowest_top_profit_item_price
FROM 
    customer_address ca
LEFT JOIN 
    TotalSales ts ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_current_addr_sk IS NOT NULL LIMIT 1)
LEFT JOIN 
    StoreSales ss ON ss.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_store_sk IS NOT NULL LIMIT 1)
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_gender IS NOT NULL
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_sk IS NOT NULL LIMIT 1)
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state, cd.cd_gender, cd.customer_count, cd.avg_purchase_estimate
HAVING 
    SUM(ts.total_net_profit) > 1000
ORDER BY 
    total_sales_profit DESC, total_store_profit DESC;
