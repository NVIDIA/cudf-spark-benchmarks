
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 5000 AND 5100
),
total_sales AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 5000 AND 5100
    GROUP BY 
        sr_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 10000 AND 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ts.total_returned, 0) AS total_returned,
    COALESCE(ts.total_return_amt, 0) AS total_return_amt,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value
FROM 
    customer_info ci
LEFT JOIN 
    total_sales ts ON ci.c_customer_sk = ts.sr_item_sk
JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk AND rs.price_rank = 1
GROUP BY 
    ci.c_customer_sk, ci.cd_gender, ci.cd_marital_status, ts.total_returned, ts.total_return_amt
HAVING 
    SUM(rs.ws_sales_price * rs.ws_quantity) > 1000
ORDER BY 
    total_sales_value DESC;
