
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
MaxProfit AS (
    SELECT 
        ws_item_sk,
        MAX(total_profit) AS max_profit
    FROM 
        SalesData
    WHERE 
        rank = 1
    GROUP BY 
        ws_item_sk
),
DailySales AS (
    SELECT 
        dd.d_date AS sale_date,
        SUM(ws.ws_net_profit) AS daily_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        dd.d_date
)
SELECT 
    da.sale_date,
    da.daily_profit,
    da.order_count,
    mp.max_profit,
    COALESCE(ci.ca_city, 'Unknown') AS city
FROM 
    DailySales da
LEFT JOIN 
    MaxProfit mp ON da.daily_profit > mp.max_profit
LEFT JOIN 
    customer_address ci ON ci.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_net_profit = (SELECT MAX(ws_net_profit) FROM web_sales)))
WHERE 
    EXTRACT(DOW FROM da.sale_date) IN (6, 0) 
ORDER BY 
    da.sale_date DESC
LIMIT 10;
