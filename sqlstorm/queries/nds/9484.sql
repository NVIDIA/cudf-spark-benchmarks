WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hbd.ib_lower_bound,
        hbd.ib_upper_bound
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band hbd ON hd.hd_income_band_sk = hbd.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458835 AND 2458885 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk, hbd.ib_lower_bound, hbd.ib_upper_bound
),
RankedSales AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.hd_income_band_sk ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_sales,
    rs.num_orders,
    rs.cd_gender,
    CONCAT(hbd.ib_lower_bound, ' - ', hbd.ib_upper_bound) AS income_band,
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    income_band hbd ON rs.hd_income_band_sk = hbd.ib_income_band_sk
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.hd_income_band_sk, rs.sales_rank;