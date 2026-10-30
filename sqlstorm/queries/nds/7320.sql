
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
final_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        ri.total_returns,
        CASE 
            WHEN si.total_sales IS NOT NULL AND ri.total_returns IS NOT NULL THEN 
                si.total_sales - ri.total_returns
            ELSE 
                si.total_sales
        END AS net_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        return_summary ri ON ci.c_customer_sk = ri.wr_returning_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.total_sales,
    fs.total_returns,
    fs.net_sales,
    RANK() OVER (ORDER BY fs.net_sales DESC) AS sales_rank
FROM 
    final_summary fs
WHERE 
    fs.net_sales > 0
ORDER BY 
    fs.net_sales DESC
LIMIT 100;
