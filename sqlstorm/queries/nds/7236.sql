
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_marital_status,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk AS customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.cd_marital_status AS marital_status,
        cs.cd_gender AS gender,
        cs.ib_lower_bound,
        cs.ib_upper_bound,
        RANK() OVER (PARTITION BY cs.ib_lower_bound ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rc.customer_sk,
    rc.total_sales,
    rc.order_count,
    rc.marital_status,
    rc.gender,
    rc.ib_lower_bound,
    rc.ib_upper_bound
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.ib_lower_bound, rc.total_sales DESC;
