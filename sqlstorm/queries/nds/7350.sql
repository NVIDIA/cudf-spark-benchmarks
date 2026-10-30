
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.c_birth_day,
        ci.c_birth_month,
        ci.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        sm.sm_type
    FROM web_sales ws
    JOIN customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2023
    AND ws.ws_quantity > 0
),
AggregatedSales AS (
    SELECT 
        sd.c_first_name,
        sd.c_last_name,
        sd.c_email_address,
        COUNT(sd.ws_order_number) AS order_count,
        SUM(sd.ws_sales_price) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        MIN(sd.c_birth_day) AS min_birth_day,
        MAX(sd.c_birth_month) AS max_birth_month
    FROM SalesData sd
    GROUP BY sd.c_first_name, sd.c_last_name, sd.c_email_address
)
SELECT 
    ag.c_first_name,
    ag.c_last_name,
    ag.c_email_address,
    ag.order_count,
    ag.total_sales,
    ag.total_profit,
    ag.avg_sales_price,
    ag.min_birth_day,
    ag.max_birth_month,
    RANK() OVER (ORDER BY ag.total_sales DESC) AS sales_rank
FROM AggregatedSales ag
WHERE ag.total_profit > 1000
ORDER BY ag.total_sales DESC
LIMIT 50;
