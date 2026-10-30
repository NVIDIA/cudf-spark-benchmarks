
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        CD.cd_gender,
        HD.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        household_demographics AS HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, CD.cd_gender, HD.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        CustomerSales cs
    INNER JOIN 
        income_band ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cs.rank_sales <= 10 
        AND cs.total_sales IS NOT NULL
),
WebReturnsSummary AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        COALESCE(wr.total_returns, 0) AS total_returns,
        COALESCE(wr.return_count, 0) AS return_count,
        (tc.total_sales - COALESCE(wr.total_returns, 0)) AS net_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        WebReturnsSummary wr ON tc.c_customer_sk = wr.wr_returning_customer_sk
)

SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_sales,
    fr.order_count,
    fr.total_returns,
    fr.return_count,
    fr.net_sales,
    CASE 
        WHEN fr.net_sales < 0 THEN 'Loss'
        WHEN fr.net_sales = 0 THEN 'No Profit'
        ELSE 'Profit'
    END AS profit_status
FROM 
    FinalReport fr
ORDER BY 
    fr.net_sales DESC;
