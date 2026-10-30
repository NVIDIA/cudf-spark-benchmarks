
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk, d.d_year, d.d_month_seq, d.d_week_seq
),
CustomerSegment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_quantity) AS segment_quantity,
        SUM(sd.total_sales) AS segment_sales,
        SUM(sd.total_discount) AS segment_discount,
        SUM(sd.total_profit) AS segment_profit,
        COUNT(DISTINCT sd.order_count) AS total_orders
    FROM SalesData sd
    JOIN customer c ON sd.ws_item_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.segment_quantity,
    cs.segment_sales,
    cs.segment_discount,
    cs.segment_profit,
    cs.total_orders,
    RANK() OVER (ORDER BY cs.segment_profit DESC) AS profit_rank
FROM CustomerSegment cs
ORDER BY cs.segment_profit DESC;
