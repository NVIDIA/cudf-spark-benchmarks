WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        ws_bill_customer_sk
), CustomerRanking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
             ws_bill_customer_sk, 
             total_sales 
         FROM 
             SalesCTE 
         WHERE 
             rank <= 5) s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
), TopCustomers AS (
    SELECT 
        c.*, 
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerRanking c
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    i.i_product_name,
    SUM(i.i_current_price) AS total_spent
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_marital_status, tc.total_sales, i.i_product_name
HAVING 
    SUM(i.i_current_price) > 100
ORDER BY 
    total_spent DESC;