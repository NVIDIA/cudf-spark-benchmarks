
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
),
AggregatedSales AS (
    SELECT 
        ca_city,
        ca_state,
        cd_gender,
        hd_income_band_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(*) AS transaction_count
    FROM 
        SalesData
    GROUP BY 
        ca_city, ca_state, cd_gender, hd_income_band_sk
)
SELECT 
    city_state_info.ca_city,
    city_state_info.ca_state,
    city_state_info.cd_gender,
    city_state_info.hd_income_band_sk,
    city_state_info.total_sales,
    city_state_info.avg_net_profit,
    city_state_info.transaction_count,
    RANK() OVER (PARTITION BY city_state_info.ca_state ORDER BY city_state_info.total_sales DESC) AS sales_rank
FROM 
    AggregatedSales city_state_info
WHERE 
    city_state_info.total_sales > (SELECT AVG(total_sales) FROM AggregatedSales)
ORDER BY 
    city_state_info.ca_state, sales_rank;
