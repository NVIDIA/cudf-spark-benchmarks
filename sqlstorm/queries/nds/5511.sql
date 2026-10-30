
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        C.c_first_name,
        C.c_last_name,
        CA.ca_city,
        CA.ca_state,
        R.r_reason_desc AS return_reason,
        D.d_year,
        D.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY D.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    LEFT JOIN 
        web_returns WR ON ws.ws_order_number = WR.wr_order_number
    LEFT JOIN 
        reason R ON WR.wr_reason_sk = R.r_reason_sk
    WHERE 
        D.d_year = 2023
    GROUP BY 
        ws.ws_order_number, C.c_first_name, C.c_last_name, CA.ca_city, CA.ca_state, R.r_reason_desc, D.d_year, D.d_month_seq
)
SELECT 
    year,
    month,
    MAX(total_profit) AS max_profit,
    MIN(total_quantity) AS min_quantity,
    COUNT(CASE WHEN profit_rank <= 10 THEN 1 END) AS top_sales_count
FROM 
    (SELECT 
        d_year AS year,
        d_month_seq AS month,
        total_profit,
        total_quantity,
        profit_rank
     FROM 
        RankedSales) AS RankedData
GROUP BY 
    year, month
ORDER BY 
    year, month;
