WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
SalesRank AS (
    SELECT 
        region_name,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        total_orders
    FROM 
        SalesRank
    WHERE 
        sales_rank <= 5
),
SuppTotal AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
UnusualCustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS unusual_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND SUBSTRING(c.c_name, 1, 3) = 'ABC'
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 3
)
SELECT 
    T.region_name,
    T.total_sales,
    T.total_orders,
    CASE 
        WHEN T.total_sales > 1000000 THEN 'High Performer'
        WHEN T.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    COALESCE(U.unusual_order_count, 0) AS unusual_customer_orders,
    COALESCE(S.total_available_quantity, 0) AS total_available_qty,
    S.avg_account_balance
FROM 
    TopRegions T
LEFT JOIN 
    UnusualCustomerOrders U ON U.c_custkey = (
        SELECT MIN(c.c_custkey) 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_orderkey IN (SELECT o_orderkey FROM orders ORDER BY o_orderdate DESC LIMIT 1)
    )
LEFT JOIN 
    SuppTotal S ON S.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_discount IN (SELECT DISTINCT l_discount FROM lineitem WHERE l_discount < 0.05)
        LIMIT 1
    )
WHERE 
    T.total_orders > (
        SELECT AVG(total_orders) FROM RegionalSales
    )
ORDER BY 
    T.total_sales DESC;
