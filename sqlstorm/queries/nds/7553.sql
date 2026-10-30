
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2023 AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.ws_item_sk,
        d.d_year,
        d.d_month_seq,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_orders
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.total_tax,
    rd.total_return_quantity,
    rd.total_return_amount,
    sd.total_orders,
    sd.d_year,
    sd.d_month_seq,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.ib_lower_bound,
    sd.ib_upper_bound
FROM SalesData sd
LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
ORDER BY sd.total_sales DESC
LIMIT 100;
