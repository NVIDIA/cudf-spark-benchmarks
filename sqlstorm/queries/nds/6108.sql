
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_net_paid, 
        d.d_date, 
        d.d_month_seq, 
        d.d_year, 
        ca.ca_state,
        cd.cd_gender, 
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2023
    AND ws.ws_net_paid > 50
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        COUNT(sd.ws_item_sk) AS transaction_count,
        COUNT(CASE WHEN sd.cd_gender = 'F' THEN 1 END) AS female_sales,
        COUNT(CASE WHEN sd.cd_gender = 'M' THEN 1 END) AS male_sales
    FROM sales_data sd
    WHERE sd.rn = 1
    GROUP BY sd.ws_item_sk
)
SELECT 
    COALESCE(item.i_item_id, 'Unknown Item') AS item_id,
    COALESCE(item.i_item_desc, 'No Description') AS item_description,
    ts.total_quantity,
    ts.total_net_paid,
    ts.transaction_count,
    ts.female_sales,
    ts.male_sales
FROM top_sales ts
LEFT JOIN item ON ts.ws_item_sk = item.i_item_sk
ORDER BY ts.total_net_paid DESC
LIMIT 10;
