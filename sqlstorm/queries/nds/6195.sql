
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) - 10 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
), 
TopSales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_paid) AS total_net_paid,
        COUNT(r.ws_order_number) AS order_count
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 10
    GROUP BY 
        r.ws_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), 
TopCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.customer_count,
        SUM(ts.total_net_paid) AS total_spent
    FROM 
        TopSales ts
    JOIN 
        web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.customer_count
)
SELECT 
    tc.cd_demo_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.customer_count,
    tc.total_spent
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
