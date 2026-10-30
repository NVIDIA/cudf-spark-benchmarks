
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        COALESCE(i.i_product_name, 'Unknown') AS product_name,
        i.i_current_price,
        COALESCE(SUM(ss.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(ss.total_profit), 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    GROUP BY 
        i.i_item_sk, 
        i.i_product_name, 
        i.i_current_price
),
customer_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
return_statistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
final_stats AS (
    SELECT 
        id.i_item_sk,
        id.product_name,
        id.i_current_price,
        id.total_quantity,
        id.total_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        cs.customer_count,
        cs.avg_purchase_estimate
    FROM 
        item_details id
    LEFT JOIN 
        return_statistics rs ON id.i_item_sk = rs.sr_item_sk
    LEFT JOIN 
        customer_stats cs ON 1=1  
)
SELECT 
    f.product_name,
    f.i_current_price,
    f.total_quantity,
    f.total_profit,
    f.total_returns,
    f.total_returned_amount,
    f.customer_count,
    f.avg_purchase_estimate,
    (f.total_profit - f.total_returned_amount) AS net_profit
FROM 
    final_stats f
WHERE 
    f.total_profit > 1000 
ORDER BY 
    net_profit DESC
LIMIT 10;
