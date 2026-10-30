
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),

sales_info AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_ship_mode_sk
),

returns_info AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
),

final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(ri.total_return_amt, 0) AS total_return_amt,
        ci.purchase_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON si.ws_ship_mode_sk = (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_code = 'STANDARD')
    LEFT JOIN 
        returns_info ri ON ri.wr_web_page_sk = (SELECT wp.wp_web_page_sk FROM web_page wp WHERE wp.wp_url LIKE '%example.com/%')
    WHERE 
        ci.purchase_rank <= 5
)

SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_sales,
    f.total_return_amt,
    (f.total_sales - f.total_return_amt) AS net_profit,
    CASE 
        WHEN f.total_sales > 1000 THEN 'High Value'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    final_report f
ORDER BY 
    net_profit DESC;
