
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ts.total_sales,
        ts.total_orders,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band_sk,
        hd.hd_buy_potential AS buy_potential
    FROM 
        TotalSales ts
    JOIN 
        customer c ON ts.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ts.total_sales > (SELECT AVG(total_sales) FROM TotalSales)
),
RankedSpenders AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        HighSpenders
)
SELECT 
    r.c_first_name AS first_name,
    r.c_last_name AS last_name,
    r.total_sales,
    r.total_orders,
    r.gender,
    r.income_band_sk,
    r.buy_potential
FROM 
    RankedSpenders r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
