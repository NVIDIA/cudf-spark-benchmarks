
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_sales,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.hd_income_band_sk
FROM 
    TopCustomers tc
INNER JOIN 
    CustomerSales cs ON tc.c_customer_id = cs.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    cs.hd_income_band_sk, 
    tc.total_sales DESC;
