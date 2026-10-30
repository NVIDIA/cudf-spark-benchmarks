
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458115 AND 2458145
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 100
), 
Filtered_Sales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2458115 AND 2458145
    GROUP BY 
        cs_item_sk
), 
Combined_Sales AS (
    SELECT 
        ws_item_sk AS item_sk, 
        total_quantity, 
        total_net_profit
    FROM 
        Sales_CTE
    UNION ALL
    SELECT 
        cs_item_sk AS item_sk, 
        total_quantity, 
        total_net_profit
    FROM 
        Filtered_Sales
), 
Ranked_Sales AS (
    SELECT 
        item_sk, 
        total_quantity, 
        total_net_profit, 
        RANK() OVER (ORDER BY total_net_profit DESC) AS overall_rank
    FROM 
        Combined_Sales
)
SELECT 
    ws.ws_item_sk,
    i.i_item_desc,
    ws.ws_net_paid,
    ws.ws_sold_date_sk,
    CASE 
        WHEN ws.ws_net_paid > 10000 THEN 'High Value'
        WHEN ws.ws_net_paid BETWEEN 5000 AND 10000 THEN 'Mid Value'
        ELSE 'Low Value' 
    END AS value_category,
    COALESCE(wp.wp_url, 'N/A') AS web_page_url,
    sa.total_quantity AS combined_quantity,
    sa.total_net_profit AS combined_net_profit,
    CASE 
        WHEN sa.overall_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_rank
FROM 
    web_sales ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    Ranked_Sales sa ON ws.ws_item_sk = sa.item_sk
WHERE 
    ws.ws_ship_date_sk IS NOT NULL
    AND (sa.total_quantity IS NULL OR sa.total_quantity > 10)
ORDER BY 
    sales_rank, combined_net_profit DESC
LIMIT 100;
