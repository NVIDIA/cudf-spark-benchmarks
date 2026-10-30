
WITH RecentSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc, 
        i_current_price, 
        i_brand
    FROM 
        item
),
CustomerCityCount AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
    HAVING 
        COUNT(DISTINCT c_customer_sk) > 10
),
SalesSummary AS (
    SELECT 
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        i.i_current_price AS current_price,
        rs.total_quantity_sold,
        rs.total_net_profit,
        cc.customer_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY rs.total_net_profit DESC) AS rank
    FROM 
        ItemDetails i
    JOIN RecentSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN CustomerCityCount cc ON cc.ca_city = (
        SELECT ca_city FROM customer_address WHERE ca_address_sk = 
            (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = 
                (SELECT c.c_customer_sk FROM customer c 
                 JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
                 ORDER BY ws.ws_net_profit DESC LIMIT 1) 
            )
    )
)

SELECT 
    ss.item_sk,
    ss.item_desc,
    ss.current_price,
    ss.total_quantity_sold,
    ss.total_net_profit,
    COALESCE(ss.customer_count, 0) AS city_customer_count,
    ss.rank,
    CASE 
        WHEN ss.rank <= 3 THEN 'Top Seller'
        WHEN ss.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Regular Seller'
    END AS sale_category
FROM 
    SalesSummary ss
WHERE 
    ss.total_net_profit > 1000
    AND (ss.rank IS NULL OR ss.rank BETWEEN 1 AND 10)
ORDER BY 
    ss.total_net_profit DESC
LIMIT 20;
