
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ra.ca_state,
        r.r_reason_desc
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ra ON c.c_current_addr_sk = ra.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND cd.cd_credit_rating IS NOT NULL
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.ca_state,
        COALESCE(rs.total_sales, 0) AS total_sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.total_sales > 1000 THEN 'High Value'
        WHEN fr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalReport fr
WHERE 
    fr.cd_marital_status = 'M' 
    AND fr.cd_gender = 'F'
ORDER BY 
    fr.total_sales DESC
LIMIT 100;
