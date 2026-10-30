
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
returns_data AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        AVG(wr_return_amt_inc_tax) AS avg_return_value
    FROM 
        web_returns
    WHERE 
        wr_return_quantity IS NOT NULL
    GROUP BY 
        wr_item_sk
),
promo_data AS (
    SELECT 
        cs_item_sk,
        COUNT(DISTINCT cs_order_number) AS promo_sales_count,
        SUM(cs_net_profit) AS promo_total_profit
    FROM 
        catalog_sales
    WHERE 
        cs_promo_sk IS NOT NULL
    GROUP BY 
        cs_item_sk
),
combined_data AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.avg_return_value, 0) AS avg_return_value,
        COALESCE(pd.promo_sales_count, 0) AS promo_sales_count,
        COALESCE(pd.promo_total_profit, 0) AS promo_total_profit
    FROM 
        sales_data sd
    FULL OUTER JOIN returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
    FULL OUTER JOIN promo_data pd ON sd.ws_item_sk = pd.cs_item_sk
),
final_data AS (
    SELECT
        *,
        CASE 
            WHEN total_profit > 1000 THEN 'HIGH' 
            WHEN total_profit BETWEEN 500 AND 1000 THEN 'MEDIUM' 
            ELSE 'LOW' 
        END AS profit_category,
        CASE 
            WHEN total_returns > 10 THEN 'Frequent Returns' 
            ELSE 'Rare Returns' 
        END AS return_behavior
    FROM 
        combined_data
)
SELECT 
    fd.ws_item_sk,
    fd.total_quantity,
    fd.total_profit,
    fd.total_returns,
    fd.avg_return_value,
    fd.promo_sales_count,
    fd.promo_total_profit,
    fd.profit_category,
    fd.return_behavior
FROM 
    final_data fd
WHERE 
    fd.total_quantity IS NOT NULL 
    AND (fd.total_profit > 500 OR fd.total_returns > 5 OR fd.promo_sales_count > 0)
ORDER BY 
    fd.total_profit DESC, 
    fd.total_returns ASC;
