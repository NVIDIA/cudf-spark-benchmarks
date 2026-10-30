
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.rank
    FROM SalesData sd
    WHERE sd.rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS total_purchases
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    tsi.ws_sold_date_sk,
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_net_profit,
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.total_purchases
FROM TopSellingItems tsi
JOIN CustomerDetails cd ON cd.total_purchases > 0
ORDER BY tsi.ws_sold_date_sk, tsi.total_net_profit DESC;
