
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.dependent_count,
        rs.total_sales
    FROM 
        CustomerDetails cd
    JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    hv.c_customer_sk,
    hv.c_first_name,
    hv.c_last_name,
    hv.ca_country,
    hv.cd_gender,
    hv.cd_marital_status,
    hv.dependent_count,
    hv.total_sales,
    CASE 
        WHEN hv.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status,
    CASE 
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Not Single' 
    END AS marital_status,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = hv.c_customer_sk) AS total_store_purchases
FROM 
    HighValueCustomers hv
LEFT JOIN 
    customer_demographics cd ON hv.c_customer_sk = cd.cd_demo_sk
WHERE 
    hv.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY 
    hv.total_sales DESC
LIMIT 100;
