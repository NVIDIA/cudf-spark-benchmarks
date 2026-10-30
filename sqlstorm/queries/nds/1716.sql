
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_web_sales_amt
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM 
        customer_demographics
),
DateRange AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        date_dim
    JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    WHERE 
        d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        d_year, d_month_seq
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(ws.total_web_sales_quantity, 0) AS total_web_sales_quantity,
    COALESCE(ws.total_web_sales_amt, 0) AS total_web_sales_amt,
    cd.purchase_band,
    dr.d_year,
    dr.d_month_seq,
    dr.total_orders
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
CROSS JOIN 
    DateRange dr
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) AND
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    total_web_sales_amt DESC,
    total_returned_amount DESC
LIMIT 100;
