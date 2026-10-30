
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Income_Dist AS (
    SELECT 
        hd.hd_income_band_sk, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_income_band_sk
),
Sales_Summary AS (
    SELECT 
        customer_sales.c_customer_sk,
        customer_sales.c_first_name,
        customer_sales.c_last_name,
        COALESCE(customer_sales.total_web_sales, 0) AS total_web_sales,
        COALESCE(customer_sales.total_catalog_sales, 0) AS total_catalog_sales,
        customer_sales.total_store_sales,
        customer_sales.total_web_returns,
        customer_sales.total_catalog_returns,
        CASE 
            WHEN customer_sales.total_web_sales + customer_sales.total_catalog_sales > 0 
            THEN ROUND((customer_sales.total_web_sales + customer_sales.total_catalog_sales) / (customer_sales.total_store_sales + NULLIF(customer_sales.total_web_returns + customer_sales.total_catalog_returns, 0)), 2)
            ELSE 0 
        END AS sales_efficiency_ratio
    FROM 
        Customer_Sales customer_sales
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.total_web_returns,
    s.total_catalog_returns,
    s.sales_efficiency_ratio,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    income_dist.customer_count
FROM 
    Sales_Summary s
LEFT JOIN 
    income_band ib ON (s.total_web_sales + s.total_catalog_sales) BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN 
    Income_Dist income_dist ON income_dist.hd_income_band_sk = (CASE 
                                                                  WHEN s.sales_efficiency_ratio > 0.5 THEN 1
                                                                  WHEN s.sales_efficiency_ratio BETWEEN 0.2 AND 0.5 THEN 2
                                                                  ELSE 3 
                                                              END)
ORDER BY 
    s.total_web_sales DESC, 
    s.total_catalog_sales DESC;
