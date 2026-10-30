
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_customer_id,
        cd.ca_city,
        cd.ca_state,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_discount, 0) AS total_discount,
        sd.total_orders
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ad.c_customer_id,
    ad.total_sales,
    ad.total_discount,
    ad.total_orders,
    ad.ca_city,
    ad.ca_state,
    CASE 
        WHEN ad.total_sales > 1000 THEN 'High Value Customer'
        WHEN ad.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    AggregatedData ad
WHERE 
    ad.total_orders > 5
ORDER BY 
    ad.total_sales DESC
LIMIT 100;
