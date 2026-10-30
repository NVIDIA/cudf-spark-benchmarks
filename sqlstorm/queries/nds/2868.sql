
WITH SalesStats AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.average_profit,
        cs.order_count
    FROM 
        SalesStats cs
    JOIN 
        customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        io.ib_income_band_sk,
        CASE
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band io ON hd.hd_income_band_sk = io.ib_income_band_sk
)
SELECT 
    d.c_customer_id,
    d.ca_city,
    d.ca_state,
    d.cd_gender,
    d.marital_status,
    tc.total_sales,
    tc.average_profit,
    tc.order_count
FROM 
    TopCustomers tc
JOIN 
    CustomerDetails d ON tc.c_customer_id = d.c_customer_id
ORDER BY 
    tc.total_sales DESC;
