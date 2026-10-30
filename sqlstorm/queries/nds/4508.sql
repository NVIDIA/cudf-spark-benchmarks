
WITH sales_data AS (
    SELECT 
        ws.ws_order_number AS order_number,
        ws.ws_item_sk AS item_sk,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_profit AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank,
        cd.cd_gender AS gender,
        cd.cd_credit_rating AS credit_rating,
        ca.ca_state AS state
    FROM 
        web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
        AND cd.cd_marital_status = 'M'
        AND ws.ws_net_profit > 0
),
top_sales AS (
    SELECT 
        order_number,
        item_sk,
        sales_price,
        net_profit,
        gender,
        credit_rating,
        state
    FROM 
        sales_data
    WHERE 
        rank <= 5
)

SELECT 
    ts.order_number,
    ts.item_sk,
    ts.sales_price,
    ts.net_profit,
    ts.gender,
    ts.credit_rating,
    COALESCE(ts.state, 'Unknown') AS state,
    SUM(ws.ws_quantity) OVER (PARTITION BY ts.state ORDER BY ts.net_profit DESC) AS total_quantity_by_state,
    CASE 
        WHEN ts.credit_rating = 'Excellent' THEN 'High Value'
        WHEN ts.credit_rating = 'Good' THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    top_sales ts
LEFT JOIN 
    web_sales ws ON ts.order_number = ws.ws_order_number AND ts.item_sk = ws.ws_item_sk
ORDER BY 
    ts.state, ts.net_profit DESC;
