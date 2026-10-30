WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierAgg AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
SalesSummary AS (
    SELECT 
        r.r_regionkey,
        SUM(ro.total_sales) AS region_sales,
        sa.supplier_count,
        sa.avg_acctbal
    FROM RankedOrders ro
    JOIN customer c ON ro.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN SupplierAgg sa ON n.n_nationkey = sa.s_nationkey
    GROUP BY r.r_regionkey, sa.supplier_count, sa.avg_acctbal
)
SELECT 
    s.r_regionkey,
    s.region_sales,
    s.supplier_count,
    s.avg_acctbal,
    ROW_NUMBER() OVER (ORDER BY s.region_sales DESC) AS rank
FROM SalesSummary s
WHERE s.region_sales > 10000
ORDER BY s.region_sales DESC, s.supplier_count DESC;