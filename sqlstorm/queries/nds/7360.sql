
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.c_first_name,
        ci.c_last_name,
        ca.ca_city,
        ca.ca_state,
        dd.d_year AS year,
        dd.d_month_seq,
        sm.sm_carrier,
        ib.ib_income_band_sk AS income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        household_demographics hd ON ci.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
        AND ws.ws_sales_price > 50
),
AggregatedData AS (
    SELECT 
        year,
        ca_city AS city,
        ca_state AS state,
        income_band_sk,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price * ws_quantity) AS total_revenue
    FROM 
        SalesData
    GROUP BY 
        year, ca_city, ca_state, income_band_sk
)
SELECT 
    year,
    city,
    state,
    income_band_sk,
    total_sales,
    total_revenue,
    RANK() OVER (PARTITION BY year, city ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    AggregatedData
ORDER BY 
    year, city, revenue_rank;
