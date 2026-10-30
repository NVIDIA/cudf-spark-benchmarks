
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
final_data AS (
    SELECT
        i.i_item_id,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        (COALESCE(sd.total_sales_amount, 0) - COALESCE(rd.total_return_amount, 0)) AS net_revenue
    FROM
        item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN return_data rd ON i.i_item_sk = rd.wr_item_sk
    WHERE 
        i.i_current_price > 50.00
        AND EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = rd.total_return_quantity OR s.s_store_sk = sd.total_sales_quantity)
)
SELECT 
    *,
    CASE 
        WHEN total_sales_quantity > 0 THEN (total_return_quantity * 100.0 / total_sales_quantity)
        ELSE NULL
    END AS return_rate,
    CASE 
        WHEN net_revenue > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    final_data
WHERE 
    net_revenue <> 0
ORDER BY 
    net_revenue DESC;
