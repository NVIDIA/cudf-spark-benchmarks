
WITH  Sales_Rank AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
Top_Customers AS (
    SELECT 
        customer_sk, 
        total_spent 
    FROM 
        Sales_Rank 
    WHERE 
        rank <= 10
), 
Customer_Details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state
), 
Returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    tc.total_spent,
    COALESCE(r.total_returned, 0) AS total_returned,
    (tc.total_spent - COALESCE(r.total_returned, 0)) AS net_spent,
    CONCAT(cd.ca_city, ', ', cd.ca_state) AS location
FROM 
    Customer_Details cd
JOIN 
    Top_Customers tc ON cd.c_customer_sk = tc.customer_sk
LEFT JOIN 
    Returns r ON cd.c_customer_sk = r.sr_customer_sk
ORDER BY 
    net_spent DESC
LIMIT 
    10;
