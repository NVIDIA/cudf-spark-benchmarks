
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        COUNT(*) AS total_sales, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
), TopProfitableItems AS (
    SELECT 
        r.ws_item_sk,
        i.i_item_desc,
        r.total_sales,
        r.total_net_profit
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.rank <= 10
), SalesTrends AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS yearly_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit_per_order
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
), RichCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE cd.cd_credit_rating = 'Excellent'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    HAVING COUNT(ws.ws_order_number) > 5
), FinalReport AS (
    SELECT 
        t.ws_item_sk AS item_id,
        t.total_sales,
        t.total_net_profit,
        r.c_first_name,
        r.c_last_name,
        r.order_count,
        r.total_profit
    FROM TopProfitableItems t
    FULL OUTER JOIN RichCustomers r ON t.ws_item_sk = r.c_customer_sk
)
SELECT 
    f.item_id,
    f.total_sales,
    f.total_net_profit,
    CASE 
        WHEN f.order_count IS NULL THEN 'No Orders'
        ELSE CAST(f.order_count AS STRING) 
    END AS order_count,
    CASE 
        WHEN f.total_profit IS NULL THEN 0
        ELSE f.total_profit 
    END AS total_profit
FROM FinalReport f
WHERE f.total_net_profit > 1000
ORDER BY f.total_net_profit DESC
LIMIT 20;
