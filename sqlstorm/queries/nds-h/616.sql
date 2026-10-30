WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales IS NOT NULL
),
AggregateData AS (
    SELECT 
        t.s_suppkey,
        t.s_name,
        co.c_custkey,
        co.order_count,
        co.total_spent,
        t.sales_rank
    FROM 
        TopSuppliers t
    LEFT JOIN 
        CustomerOrders co ON co.total_spent > 5000 AND t.sales_rank <= 5
)
SELECT 
    ad.s_suppkey, 
    ad.s_name, 
    ad.c_custkey, 
    COALESCE(ad.order_count, 0) AS order_count,
    COALESCE(ad.total_spent, 0) AS total_spent,
    ROUND(AVG(ad.total_spent) OVER (PARTITION BY ad.s_suppkey), 2) AS avg_spent
FROM 
    AggregateData ad
WHERE 
    ad.order_count IS NULL OR ad.total_spent IS NOT NULL
ORDER BY 
    ad.s_suppkey, ad.c_custkey;