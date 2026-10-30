
WITH  sales_data AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY
        ss_sold_date_sk,
        ss_item_sk
),
top_selling_items AS (
    SELECT 
        sd.ss_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS item_rank
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 5
),
customer_return_data AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(t.total_quantity, 0) AS total_quantity_sold,
    COALESCE(t.total_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    (COALESCE(t.total_profit, 0) - COALESCE(r.total_returned_amount, 0)) AS net_profit_after_returns,
    CASE 
        WHEN COALESCE(r.total_returns, 0) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_returns
FROM 
    item i
LEFT JOIN 
    top_selling_items t ON i.i_item_sk = t.ss_item_sk
LEFT JOIN 
    customer_return_data r ON t.ss_item_sk = r.sr_item_sk
WHERE 
    (i.i_current_price * 1.1) > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_item_sk = i.i_item_sk)
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
