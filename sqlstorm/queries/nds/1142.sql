
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(CASE WHEN sr_return_quantity > 0 THEN 1 END) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(sr_return_tax, 0)) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cr.c_customer_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_tax,
        sd.total_orders,
        sd.average_order_value
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        SalesData sd ON cr.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count,
    d.d_date AS report_date,
    coalesce(ad.ca_city, 'Unknown') AS location,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    combined.total_sales,
    combined.total_return_amount,
    combined.total_orders,
    combined.average_order_value
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    CombinedData combined ON c.c_customer_sk = combined.c_customer_sk
LEFT JOIN 
    customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
CROSS JOIN 
    date_dim d
WHERE 
    d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
ORDER BY 
    total_sales DESC, total_returns DESC;
