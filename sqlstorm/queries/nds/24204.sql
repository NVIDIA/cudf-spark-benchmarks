
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        ws.ws_coupon_amt,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ship_date_sk,
        cs.cs_coupon_amt,
        COALESCE(cs.cs_net_profit, 0) AS net_profit,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS rank
    FROM catalog_sales cs
    WHERE 
        cs.cs_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
RankingData AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.net_profit) AS total_net_profit,
        AVG(CASE WHEN sd.rank <= 5 THEN sd.ws_sales_price END) AS avg_top_5_price
    FROM SalesData sd
    WHERE sd.net_profit > 0 
    GROUP BY sd.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN cr.cr_return_quantity IS NOT NULL THEN cr.cr_order_number END) AS returns_count,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        MAX(CASE WHEN c.c_birth_month = 12 THEN 'Holiday Season' ELSE 'Non-Holidays' END) AS seasonal_status
    FROM customer c
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.orders_count,
    cs.returns_count,
    ROUND(CAST(cs.orders_count AS decimal) / NULLIF(cs.returns_count, 0), 2) AS order_return_ratio,
    COALESCE(rd.total_quantity, 0) AS total_quantity,
    COALESCE(rd.total_net_profit, 0) AS total_net_profit,
    rd.avg_top_5_price
FROM CustomerStats cs
LEFT JOIN RankingData rd ON cs.c_customer_sk = rd.ws_item_sk
WHERE (ROUND(CAST(cs.orders_count AS decimal) / NULLIF(cs.returns_count, 0), 2) > 10 OR cs.seasonal_status = 'Holiday Season')
ORDER BY total_net_profit DESC
LIMIT 100;
