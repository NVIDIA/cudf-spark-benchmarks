
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT('Street: ', ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(cd.cd_education_status, ' - Income Band: ', ib.ib_lower_bound, ' to ', ib.ib_upper_bound) AS demographic_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_bill_customer_sk
),
returns_info AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.demographic_info,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.avg_sales_price, 0.00) AS avg_sales_price,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_amount, 0.00) AS total_return_amount
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN 
    returns_info ri ON si.ws_item_sk = ri.wr_item_sk
ORDER BY 
    ci.full_name;
