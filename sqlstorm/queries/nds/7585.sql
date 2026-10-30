
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        date_dim.d_year,
        date_dim.d_month_seq,
        w.w_warehouse_name,
        sm.sm_carrier
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        date_dim.d_year BETWEEN 2020 AND 2023
        AND ws.ws_sales_price > 0
),
AggregatedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        hd_income_band_sk,
        cd_gender,
        cd_marital_status,
        w_warehouse_name,
        sm_carrier,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_item_sk) AS total_sales_count,
        AVG(ws_sales_price) AS average_sales_price,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        SalesData
    GROUP BY 
        d_year, 
        d_month_seq, 
        hd_income_band_sk, 
        cd_gender, 
        cd_marital_status, 
        w_warehouse_name, 
        sm_carrier
)
SELECT 
    d_year,
    d_month_seq,
    hd_income_band_sk,
    cd_gender,
    cd_marital_status,
    w_warehouse_name,
    sm_carrier,
    total_net_profit,
    total_sales_count,
    average_sales_price,
    total_quantity_sold
FROM 
    AggregatedSales
ORDER BY 
    d_year, d_month_seq, total_net_profit DESC;
