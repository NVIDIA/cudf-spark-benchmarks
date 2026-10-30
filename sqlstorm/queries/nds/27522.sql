
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        w.w_warehouse_name
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
returns_info AS (
    SELECT 
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        rc.r_reason_desc AS return_reason
    FROM store_returns sr
    JOIN reason rc ON sr.sr_reason_sk = rc.r_reason_sk
),
final_benchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.ws_order_number,
        si.ws_item_sk,
        si.ws_sales_price,
        si.ws_quantity,
        si.ws_net_profit,
        ri.sr_return_quantity,
        ri.sr_return_amt,
        ri.return_reason
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_id = CAST(si.ws_order_number AS CHAR(16))
    LEFT JOIN returns_info ri ON si.ws_item_sk = ri.sr_item_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_sales_price) AS average_price,
    SUM(sr_return_quantity) AS total_returns,
    SUM(sr_return_amt) AS total_return_value,
    return_reason
FROM final_benchmark
GROUP BY cd_gender, cd_marital_status, return_reason
ORDER BY cd_gender, total_profit DESC;
