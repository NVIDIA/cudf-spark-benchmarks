WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_sales_price AS sale_amount,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
        AND d.d_dow NOT IN (6, 0)  
), 
CustomerSales AS (
    SELECT 
        rc.c_customer_sk, 
        SUM(sd.sale_amount) AS total_sales
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        rc.c_customer_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cs.total_sales,
    COALESCE(cs.total_sales, 0) AS total_sales_non_null,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    RankedCustomers c
LEFT JOIN 
    CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    c.rank = 1  
ORDER BY 
    c.c_last_name ASC, 
    c.c_first_name ASC;