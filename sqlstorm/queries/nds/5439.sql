
WITH SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws_promo_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        c.c_current_cdemo_sk,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk, d.d_year ORDER BY ws.ws_ship_date_sk) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),

AggregateSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(sd.ws_item_sk) AS total_transactions,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        sd.d_year,
        sd.d_month_seq
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_item_sk, sd.d_year, sd.d_month_seq
)

SELECT 
    asales.ws_item_sk,
    asales.total_sales,
    asales.total_transactions,
    asales.avg_sales_price,
    COUNT(DISTINCT sd.ca_country) AS unique_countries
FROM 
    AggregateSales asales
JOIN 
    SalesData sd ON asales.ws_item_sk = sd.ws_item_sk
GROUP BY 
    asales.ws_item_sk, asales.total_sales, asales.total_transactions, asales.avg_sales_price
ORDER BY 
    total_sales DESC
LIMIT 100;
