
WITH Ranked_Sales AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk, 
        ws_item_sk
),
Top_Products AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM 
        Ranked_Sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store_returns sr ON rs.ws_item_sk = sr.sr_item_sk AND sr.sr_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
    LEFT JOIN 
        web_returns wr ON rs.ws_item_sk = wr.wr_item_sk AND wr.wr_returning_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        rs.ws_item_sk, 
        i.i_item_desc, 
        i.i_current_price
),
Final_Result AS (
    SELECT 
        tp.i_item_desc,
        tp.i_current_price,
        tp.total_returns,
        tp.total_web_returns,
        (tp.total_returns + tp.total_web_returns) AS combined_returns
    FROM 
        Top_Products tp
    WHERE 
        tp.total_returns > 0 OR tp.total_web_returns > 0
)
SELECT 
    fr.i_item_desc,
    fr.i_current_price,
    fr.combined_returns,
    CASE 
        WHEN fr.combined_returns > 100 THEN 'High Return'
        WHEN fr.combined_returns BETWEEN 50 AND 100 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    Final_Result fr
ORDER BY 
    fr.combined_returns DESC
LIMIT 10;
