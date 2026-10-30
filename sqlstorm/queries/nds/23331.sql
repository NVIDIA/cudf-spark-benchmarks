
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_store_sales DESC, total_web_sales DESC) AS sales_rank
    FROM 
        CustomerStats
),
TopCustomers AS (
    SELECT 
        c.*, 
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store' 
            ELSE 'Web' 
        END AS preferred_channel
    FROM 
        RankedCustomers c
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_sales,
    tc.total_web_sales,
    COALESCE(tc.preferred_channel, 'Neither') AS channel,
    CONCAT('Customer: ', tc.c_first_name, ' ', tc.c_last_name, ' | Store Sales: ', tc.total_store_sales, ' | Web Sales: ', tc.total_web_sales) AS summary
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_store_sales DESC, tc.total_web_sales DESC;
