
WITH RankedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
),
SalesWithDemographics AS (
    SELECT 
        f.c_customer_sk,
        f.c_first_name,
        f.c_last_name,
        f.cd_gender,
        f.cd_marital_status,
        f.cd_purchase_estimate,
        COALESCE(r.total_sales, 0) AS total_sales
    FROM 
        FilteredCustomers f
    LEFT JOIN 
        RankedSales r ON f.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        f.cd_gender = 'M' AND f.cd_marital_status = 'S'
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.cd_purchase_estimate,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High spender'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium spender'
        ELSE 'Low spender' 
    END AS spending_category,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = s.c_customer_sk) AS store_visits,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = s.c_customer_sk) AS web_visits
FROM 
    SalesWithDemographics s
WHERE 
    s.total_sales > 0
ORDER BY 
    s.total_sales DESC
LIMIT 100;
