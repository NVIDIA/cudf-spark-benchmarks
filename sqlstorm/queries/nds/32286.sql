
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
customer_return_data AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_value
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_returning_customer_sk
),
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ss.total_revenue, 0) AS total_revenue,
        COALESCE(crd.total_returned, 0) AS total_returned_items,
        COALESCE(crd.total_returned_value, 0) AS total_returned_value,
        AVG(i.i_current_price) OVER(PARTITION BY i.i_item_sk) AS avg_price
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        customer_return_data crd ON i.i_item_sk = crd.wr_returning_customer_sk
)
SELECT 
    ia.i_item_id,
    ia.total_quantity_sold,
    ia.total_revenue,
    ia.total_returned_items,
    ia.total_returned_value,
    ia.avg_price,
    CASE 
        WHEN ia.total_revenue = 0 THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM 
    item_performance ia
WHERE 
    ia.total_quantity_sold > 0
ORDER BY 
    ia.total_revenue DESC
LIMIT 10;

