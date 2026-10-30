
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, 
        i.i_item_desc, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        d.d_year, 
        d.d_month_seq
),
ranked_sales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM sales_data sd
)
SELECT 
    i_item_desc AS item_desc, 
    total_quantity, 
    total_net_paid, 
    order_count, 
    c_first_name, 
    c_last_name, 
    cd_gender, 
    cd_marital_status,
    d_year,
    d_month_seq
FROM ranked_sales
WHERE sales_rank <= 10
ORDER BY d_year, d_month_seq, total_net_paid DESC;
