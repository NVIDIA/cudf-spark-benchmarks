WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_lineitem_price
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS total_sales_by_region,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    rs.total_sales_by_region,
    rs.supplier_count,
    RANK() OVER (ORDER BY rs.total_sales_by_region DESC) AS sales_rank
FROM RegionSales rs
JOIN region r ON rs.n_regionkey = r.r_regionkey
ORDER BY rs.total_sales_by_region DESC, r.r_name;