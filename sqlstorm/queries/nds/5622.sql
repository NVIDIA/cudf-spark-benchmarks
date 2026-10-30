
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        ca.ca_zip,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS customer_rank,
        rs.ws_bill_customer_sk
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        RankedSales AS rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesDetails AS (
    SELECT 
        ts.customer_rank,
        ts.ca_city,
        ts.ca_state,
        ts.ca_country,
        ts.ca_zip,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        TopCustomers AS ts
    JOIN 
        web_sales AS ws ON ts.ws_bill_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ts.customer_rank, ts.ca_city, ts.ca_state, ts.ca_country, ts.ca_zip
)
SELECT 
    customer_rank,
    ca_city, 
    ca_state, 
    ca_country, 
    ca_zip, 
    total_net_paid, 
    avg_discount
FROM 
    SalesDetails
WHERE 
    avg_discount > 0
ORDER BY 
    total_net_paid DESC, avg_discount ASC;
