
WITH enriched_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        CASE 
            WHEN ws.ws_net_profit > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
),
aggregate_sales AS (
    SELECT 
        profit_status,
        ca_state,
        COUNT(*) AS sales_count,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        enriched_sales
    GROUP BY 
        profit_status, ca_state
)
SELECT 
    profit_status,
    ca_state,
    sales_count,
    total_sales,
    total_net_profit,
    ROUND(total_sales / NULLIF(sales_count, 0), 2) AS avg_sales_per_order,
    ROUND(total_net_profit / NULLIF(sales_count, 0), 2) AS avg_profit_per_order
FROM 
    aggregate_sales
ORDER BY 
    profit_status, total_net_profit DESC;
