
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
), 
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_shipping_methods
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
), 
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_returnamt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
), 
CombinedResults AS (
    SELECT 
        rc.c_customer_id,
        ss.total_sales,
        cs.return_count,
        COALESCE(cs.total_returnamt, 0) AS total_returnamt,
        ss.distinct_shipping_methods,
        rc.gender_rank
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cs ON rc.c_customer_sk = cs.sr_customer_sk
    WHERE 
        rc.gender_rank = 1
)

SELECT 
    cr.c_customer_id,
    cr.total_sales,
    cr.return_count,
    CASE 
        WHEN cr.total_returnamt > cr.total_sales THEN 'High Returns'
        WHEN cr.total_sales > 5000 AND cr.return_count > 5 THEN 'Promising Customer'
        ELSE 'Standard Customer'
    END AS customer_status,
    cr.distinct_shipping_methods,
    CONCAT('Customer ID: ', cr.c_customer_id, ' | Total Sales: ', COALESCE(cr.total_sales, 0)) AS sales_info
FROM 
    CombinedResults cr
ORDER BY 
    cr.total_sales DESC, cr.return_count DESC
LIMIT 10;
