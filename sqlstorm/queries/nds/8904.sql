
WITH SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        ca.ca_city,
        cd.cd_gender,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year >= 2020
),
AggregateSales AS (
    SELECT 
        d_year,
        d_month_seq,
        ca_city,
        sm_type,
        cd_gender,
        ib_income_band_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, ca_city, sm_type, cd_gender, ib_income_band_sk
)
SELECT 
    d_year, 
    d_month_seq, 
    ca_city, 
    sm_type, 
    cd_gender, 
    ib_income_band_sk, 
    total_quantity, 
    total_net_profit,
    (total_net_profit / NULLIF(total_quantity, 0)) AS avg_profit_per_item
FROM 
    AggregateSales
ORDER BY 
    d_year, d_month_seq, ca_city;
