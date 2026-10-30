WITH TotalSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        MAX(l_shipdate) AS last_ship_date
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(ts.total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
)
SELECT 
    rc.rank,
    rc.c_name,
    rc.order_count,
    rc.total_spent
FROM 
    RankedCustomers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.rank;