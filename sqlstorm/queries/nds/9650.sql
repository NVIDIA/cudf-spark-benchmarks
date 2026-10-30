
WITH SalesAggregates AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(ws_ext_tax) AS total_tax,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458000 AND 2458100
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        sa.total_sales,
        sa.order_count,
        sa.avg_discount,
        sa.total_tax,
        sa.total_profit
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesAggregates sa ON cd.c_customer_sk = sa.customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    c.ca_country,
    c.total_sales,
    c.order_count,
    c.avg_discount,
    c.total_tax,
    c.total_profit
FROM 
    CombinedData c
WHERE 
    c.total_sales > (SELECT AVG(total_sales) FROM SalesAggregates)
    AND c.cd_gender = 'F'
ORDER BY 
    c.total_sales DESC
LIMIT 50;
