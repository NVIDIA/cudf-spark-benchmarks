
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_country,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        ws.ws_sales_price > 100.00
), 
ProfitAnalysis AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN ws_order_number END) AS total_female_orders,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN ws_order_number END) AS total_male_orders,
        AVG(ws_sales_price) AS average_sales_price
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_week_seq
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    total_orders,
    total_quantity,
    total_net_profit,
    total_female_orders,
    total_male_orders,
    average_sales_price,
    CASE 
        WHEN total_net_profit > 50000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 20000 AND 50000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    ProfitAnalysis
ORDER BY 
    d_year, d_month_seq, d_week_seq;
