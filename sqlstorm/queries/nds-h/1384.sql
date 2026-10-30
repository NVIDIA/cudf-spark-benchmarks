WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank 
    FROM 
        SupplierSales s
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
), HighSpendingCustomers AS (
    SELECT 
        co.*, 
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank 
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 1000
), FinalReport AS (
    SELECT 
        rss.s_suppkey, 
        rss.s_name, 
        hsc.c_custkey, 
        hsc.c_name, 
        hsc.order_count, 
        hsc.total_spent 
    FROM 
        RankedSales rss 
    LEFT JOIN 
        HighSpendingCustomers hsc ON rss.sales_rank <= 10 AND hsc.spending_rank <= 10
)
SELECT 
    fr.s_suppkey, 
    fr.s_name, 
    fr.c_custkey, 
    fr.c_name, 
    COALESCE(fr.order_count, 0) AS order_count, 
    COALESCE(fr.total_spent, 0) AS total_spent
FROM 
    FinalReport fr
ORDER BY 
    fr.s_suppkey, fr.c_custkey;
