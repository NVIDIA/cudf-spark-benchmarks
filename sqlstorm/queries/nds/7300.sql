
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 9000 AND 9010
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesInsights AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_credit_rating = 'Good' 
        AND cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
), 
RankedSales AS (
    SELECT 
        rs.*,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        SalesInsights rs
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_sales,
    rs.order_count,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_credit_rating,
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10;
