
WITH  seasonal_sales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
info_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.income_band,
        COUNT(ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(COALESCE(ir.gross_margin, 0)) AS total_margin,
        SUM(COALESCE(returns.total_returns, 0)) AS total_returns
    FROM 
        customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN (
        SELECT 
            SUM(ws.ws_net_paid) AS gross_margin,
            ws.ws_bill_customer_sk
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_bill_customer_sk
    ) ir ON ci.c_customer_sk = ir.ws_bill_customer_sk
    LEFT JOIN (
        SELECT 
            sr.sr_customer_sk,
            SUM(sr.sr_return_amt_inc_tax) AS total_returns
        FROM 
            store_returns sr
        GROUP BY 
            sr.sr_customer_sk
    ) returns ON ci.c_customer_sk = returns.sr_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.income_band
)
SELECT 
    customer_summary.c_first_name,
    customer_summary.c_last_name,
    customer_summary.cd_gender,
    customer_summary.cd_marital_status,
    customer_summary.total_web_orders,
    customer_summary.total_web_profit,
    si.total_sales,
    CASE 
        WHEN customer_summary.total_web_profit IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    info_summary customer_summary
LEFT JOIN (
    SELECT 
        SUM(total_sales) AS total_sales
    FROM 
        seasonal_sales
    WHERE 
        total_sales > (
            SELECT AVG(total_sales) FROM seasonal_sales
        )
) si ON TRUE
WHERE 
    customer_summary.total_web_orders > 0
ORDER BY 
    customer_summary.total_web_profit DESC
LIMIT 100;
