
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2410
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.total_returned_quantity,
    cr.total_returned_amount,
    pi.order_count AS popular_item_order_count,
    pi.total_sales AS popular_item_sales
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    PopularItems pi ON pi.ws_item_sk IN (
        SELECT 
            sr_item_sk 
        FROM 
            store_returns 
        WHERE 
            sr_customer_sk = cd.c_customer_sk
    )
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    AND (cr.total_returned_quantity IS NOT NULL OR cr.total_returned_amount IS NOT NULL)
ORDER BY 
    COALESCE(cr.total_returned_amount, 0) DESC;
