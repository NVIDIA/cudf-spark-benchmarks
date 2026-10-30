
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ship_date_sk,
        d.d_date as ship_date,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        st.s_store_name,
        sm.sm_carrier
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN store st ON ws.ws_ship_addr_sk = st.s_store_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2023 AND d.d_moy IN (11, 12)
),
AggregatedSales AS (
    SELECT 
        ship_date,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM SalesData
    GROUP BY 
        ship_date,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status
)
SELECT 
    ship_date,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_first_name || ' ' || c_last_name) AS unique_customers,
    SUM(total_quantity) AS total_items_sold,
    SUM(total_sales) AS total_revenue
FROM AggregatedSales
GROUP BY 
    ship_date, cd_gender, cd_marital_status
ORDER BY 
    ship_date,
    cd_gender,
    cd_marital_status;
