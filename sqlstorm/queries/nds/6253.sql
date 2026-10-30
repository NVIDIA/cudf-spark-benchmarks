
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq,
        c.c_birth_year,
        cd.cd_marital_status
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        d.d_year, 
        d.d_month_seq, 
        c.c_birth_year, 
        cd.cd_marital_status
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesSummary ss
)
SELECT 
    ti.ws_item_sk,
    ti.sales_rank,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_profit,
    ss.d_year,
    ss.d_month_seq,
    ss.c_birth_year,
    ss.cd_marital_status
FROM TopItems ti
JOIN SalesSummary ss ON ti.ws_item_sk = ss.ws_item_sk
WHERE ti.sales_rank <= 10
ORDER BY ss.d_year, ss.total_sales DESC;
