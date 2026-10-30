
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ss.ss_ticket_number) AS number_of_sales,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk >= 1500 
    GROUP BY 
        c.c_customer_sk
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(cs.number_of_sales) AS total_customers,
        SUM(cs.total_sales) AS total_sales_value
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesByDate AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2001-01-01' AND '2001-12-31' 
    GROUP BY 
        d.d_date
)
SELECT 
    sb.d_date,
    db.cd_gender,
    db.cd_marital_status,
    db.cd_education_status,
    db.total_customers,
    db.total_sales_value,
    sb.daily_sales
FROM 
    SalesByDate sb
JOIN 
    Demographics db ON sb.daily_sales > 1000
ORDER BY 
    sb.d_date, db.total_sales_value DESC
LIMIT 100;
