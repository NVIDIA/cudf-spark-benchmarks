
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, h.hd_income_band_sk
), 
RankedCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_sales,
        cp.cd_gender,
        cp.cd_marital_status,
        cp.hd_income_band_sk,
        DENSE_RANK() OVER (ORDER BY cp.total_sales DESC) AS sales_rank
    FROM 
        CustomerPurchase cp
)
SELECT 
    rc.sales_rank,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rc.cd_gender,
    rc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    RankedCustomers rc
JOIN 
    income_band ib ON rc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    rc.sales_rank <= 100
ORDER BY 
    rc.sales_rank;
