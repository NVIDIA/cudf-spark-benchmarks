
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_profit,
        SUM(s.ss_quantity) AS total_quantity,
        AVG(s.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ActiveCustomers AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS active_customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales > 0
    GROUP BY 
        ca.ca_address_sk
),
SalesData AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    ac.ca_address_sk,
    ac.active_customer_count,
    sd.d_year,
    sd.d_month_seq,
    sd.total_web_sales,
    sd.average_net_profit
FROM 
    ActiveCustomers ac
JOIN 
    SalesData sd ON sd.d_year >= (SELECT MAX(d_year) - 1 FROM SalesData)
ORDER BY 
    ac.active_customer_count DESC, sd.total_web_sales DESC
LIMIT 100;
