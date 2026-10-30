
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        ca.ca_city,
        SUM(CASE WHEN rs.sales_rank = 1 THEN rs.ws_quantity ELSE 0 END) AS highest_quantity_sold
    FROM 
        item i
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_credit_rating IS NOT NULL ORDER BY cd.cd_demo_sk LIMIT 1)
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name, credit_rating, ca.ca_city
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.credit_rating,
    id.ca_city,
    COALESCE(ts.total_net_profit, 0) AS total_profit,
    id.highest_quantity_sold
FROM 
    ItemDetails id
LEFT JOIN 
    TotalSales ts ON id.i_item_sk = ts.ws_item_sk
WHERE 
    id.highest_quantity_sold > 0
ORDER BY 
    total_profit DESC, id.i_product_name;
