
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_month_seq BETWEEN 5 AND 7
),
AggregatedData AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_week_seq
)
SELECT 
    ad.d_year,
    ad.d_month_seq,
    ad.d_week_seq,
    ad.total_quantity,
    ad.total_sales,
    ROUND(ad.total_sales / NULLIF(ad.total_quantity, 0), 2) AS avg_price_per_unit
FROM 
    AggregatedData ad
ORDER BY 
    ad.d_year, 
    ad.d_month_seq, 
    ad.d_week_seq;
