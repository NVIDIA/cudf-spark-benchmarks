
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),

SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458538 AND 2458538 + 30
),

AggregatedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales,
        COUNT(s.ws_item_sk) AS items_purchased
    FROM 
        CustomerData c
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.total_sales,
    a.items_purchased,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    AggregatedData a
WHERE 
    a.total_sales IS NOT NULL
ORDER BY 
    a.total_sales DESC
LIMIT 100;
