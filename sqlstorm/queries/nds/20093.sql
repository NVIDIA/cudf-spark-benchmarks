WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        ws_net_profit,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_ext_discount_amt,
        ws_ext_sales_price,
        ws_ext_tax,
        (CASE 
            WHEN ws_net_profit IS NULL THEN 0
            ELSE ws_net_profit
         END) AS adjusted_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_net_profit IS NOT NULL)
),
TopProfitableItems AS (
    SELECT 
        ws_item_sk,
        MAX(adjusted_profit) AS max_profit,
        SUM(ws_net_paid) AS total_paid,
        COUNT(*) AS sales_count
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
    GROUP BY 
        ws_item_sk
)

SELECT 
    TPI.ws_item_sk,
    TPI.max_profit,
    TPI.total_paid,
    TPI.sales_count,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_item_sk = TPI.ws_item_sk) AS total_orders,
    COALESCE((SELECT 
                   SUM(ss_quantity) 
               FROM 
                   store_sales 
               WHERE 
                   ss_item_sk = TPI.ws_item_sk), 0) AS total_store_sales,
    COALESCE((SELECT 
                   SUM(ws_quantity) 
               FROM 
                   web_sales 
               WHERE 
                   ws_item_sk = TPI.ws_item_sk), 0) AS total_web_sales,
    CASE 
        WHEN TPI.total_paid > 10000 THEN 'High Value'
        WHEN TPI.total_paid > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment
FROM 
    TopProfitableItems TPI
ORDER BY 
    TPI.max_profit DESC, 
    TPI.sales_count DESC
LIMIT 10;