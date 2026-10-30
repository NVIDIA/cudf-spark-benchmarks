WITH RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sale_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING AVG(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_suppkey,
        s.s_name,
        COALESCE(Rank.total_sales, 0) AS total_sales
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN RankedSales Rank ON s.s_suppkey = Rank.s_suppkey AND Rank.sale_rank <= 10
),
FinalReport AS (
    SELECT 
        sd.region_name,
        sd.nation_name,
        sd.s_name,
        sd.total_sales,
        COALESCE(hvc.avg_order_value, 0) AS avg_order_value
    FROM SupplierDetails sd
    LEFT JOIN HighValueCustomers hvc ON sd.s_suppkey = hvc.c_custkey
)

SELECT 
    region_name, 
    nation_name, 
    s_name, 
    total_sales, 
    avg_order_value,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category
FROM FinalReport
ORDER BY region_name, nation_name, total_sales DESC
LIMIT 50;

