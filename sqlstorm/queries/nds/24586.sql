
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rank
    FROM store_returns
    WHERE sr_return_quantity > 0
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        COUNT(DISTINCT c.c_first_name) AS unique_first_names,
        COUNT(DISTINCT cd.cd_demo_sk) AS unique_demo_ids
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
),
WebSalesDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_ship_customers
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),
SubqueryExample AS (
    SELECT
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_sales_value
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_item_sk
    HAVING COUNT(*) > 1
), 
FinalSalesData AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(sr.rank, 0) AS return_rank,
        cs.c_customer_id,
        cs.male_count,
        cs.female_count,
        cs.unique_first_names,
        cs.unique_demo_ids,
        wd.total_net_profit,
        wd.unique_ship_customers
    FROM SubqueryExample s
    LEFT JOIN RankedReturns sr ON s.ws_item_sk = sr.sr_item_sk
    JOIN CustomerStats cs ON cs.unique_first_names > 5
    JOIN WebSalesDetails wd ON wd.ws_order_number = s.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.return_rank,
    f.c_customer_id,
    f.male_count,
    f.female_count,
    f.total_net_profit,
    f.unique_ship_customers,
    (SELECT COUNT(*) FROM store WHERE s_city = 'Los Angeles') AS count_la_stores,
    CASE 
        WHEN f.total_net_profit IS NULL THEN 'Profit Unknown' 
        ELSE 'Profit Known' 
    END AS profit_status
FROM FinalSalesData f
WHERE f.return_rank BETWEEN 1 AND 3
ORDER BY f.total_net_profit DESC;
