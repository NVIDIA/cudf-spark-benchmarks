
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_list_price) AS avg_list_price,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AddressDetails AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ad.c_customer_sk AS customer_id,
    ad.ca_city,
    ad.ca_state,
    ad.cd_gender,
    ad.cd_marital_status,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cr.return_count, 0) AS total_returns,
    CASE 
        WHEN COALESCE(cs.total_sales, 0) = 0 THEN 0
        ELSE (COALESCE(cr.return_count, 0) * 100.0 / NULLIF(cs.total_sales, 0)) 
    END AS return_percentage,
    CASE 
        WHEN RANK() OVER (ORDER BY COALESCE(cs.total_sales, 0) - COALESCE(cr.return_count, 0) DESC) <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    AddressDetails ad
LEFT JOIN 
    SalesSummary cs ON ad.c_customer_sk = cs.customer_sk
LEFT JOIN 
    CustomerReturns cr ON ad.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    ad.rn = 1
ORDER BY 
    return_percentage DESC, total_sales DESC;
