
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Unknown'), 'Standard') AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesByCustomer AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_purchase,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)

SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SBC.total_purchase, 0) AS total_purchase,
    COALESCE(SBC.order_count, 0) AS order_count,
    RS.total_sales AS highest_sales,
    CASE 
        WHEN RS.rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_type
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesByCustomer SBC ON cd.c_customer_id = SBC.c_customer_id
LEFT JOIN 
    RankedSales RS ON SBC.total_purchase = RS.total_sales
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_purchase_estimate > 1000) 
    AND RS.total_sales IS NOT NULL
ORDER BY 
    cd.cd_gender, total_purchase DESC;
