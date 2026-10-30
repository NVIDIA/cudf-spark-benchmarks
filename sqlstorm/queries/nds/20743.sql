
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        CASE 
            WHEN ws.ws_sales_price = 0 THEN NULL 
            ELSE (ws.ws_ext_sales_price / ws.ws_sales_price) 
        END AS price_ratio,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
), HighValueItems AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.price_ratio) AS max_price_ratio
    FROM RankedSales rs
    WHERE rs.price_ratio IS NOT NULL
    GROUP BY rs.ws_item_sk
    HAVING MAX(rs.price_ratio) > 1
), ImportantRegions AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'USA'
    GROUP BY ca.ca_city, ca.ca_state
    HAVING COUNT(DISTINCT c.c_customer_sk) > 5
), SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    INNER JOIN HighValueItems hvi ON ws.ws_item_sk = hvi.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_net_profit,
    sd.avg_sales_price,
    ir.ca_city,
    ir.ca_state
FROM SalesDetails sd
LEFT JOIN ImportantRegions ir ON ir.customer_count > 10
WHERE sd.total_net_profit > (
    SELECT AVG(sd2.total_net_profit) 
    FROM SalesDetails sd2 
    WHERE sd2.total_quantity > 100
) OR ir.ca_state IS NULL
ORDER BY sd.total_net_profit DESC, ir.ca_city ASC;
