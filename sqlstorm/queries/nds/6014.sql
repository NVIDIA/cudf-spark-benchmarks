
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq = 3
        )
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.ca_city,
        d.ca_state
    FROM 
        customer c
    JOIN 
        customer_address d ON c.c_current_addr_sk = d.ca_address_sk
),
SalesDetail AS (
    SELECT 
        t.ws_order_number,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        t.ws_sales_price
    FROM 
        TopSales t
    JOIN 
        web_sales s ON t.ws_order_number = s.ws_order_number AND t.ws_item_sk = s.ws_item_sk
    JOIN 
        CustomerInfo ci ON s.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    sd.c_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.ca_city,
    sd.ca_state,
    SUM(sd.ws_sales_price) AS total_sales_amount
FROM 
    SalesDetail sd
GROUP BY 
    sd.c_customer_sk, sd.c_first_name, sd.c_last_name, sd.ca_city, sd.ca_state
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
