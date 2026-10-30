WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
full_report AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_band,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM 
        customer_data cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_email_address,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.income_band,
    fr.order_count,
    fr.total_sales,
    CASE 
        WHEN fr.total_sales > 1000 THEN 'High Value'
        WHEN fr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_segment,
    NULLIF(fr.total_sales, 0) AS non_zero_sales 
FROM 
    full_report fr
WHERE 
    fr.cd_gender = 'F' 
    AND (fr.income_band IS NOT NULL OR fr.order_count > 0)
ORDER BY 
    fr.total_sales DESC, fr.c_email_address;