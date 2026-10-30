
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY ps.ps_partkey
),
SnazzySuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_supplycost) AS unique_costs
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_comment NOT LIKE '%test%'
    GROUP BY s.s_suppkey, s.s_name
),
FinalResults AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS total_supplier_sales,
        COUNT(DISTINCT ss.ps_partkey) AS unique_parts
    FROM SupplierSales ss
    JOIN partsupp ps ON ss.ps_partkey = ps.ps_partkey
    LEFT JOIN nation n ON ps.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost > 100)
    GROUP BY n.n_name
)

SELECT 
    r.r_name,
    COALESCE(fr.total_supplier_sales, 0) AS total_supplier_sales,
    COALESCE(fr.unique_parts, 0) AS unique_parts,
    ROW_NUMBER() OVER (ORDER BY COALESCE(fr.total_supplier_sales, 0) DESC) AS sales_rank
FROM region r
LEFT JOIN FinalResults fr ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name LIKE 'A%' LIMIT 1)
WHERE EXISTS (SELECT 1 FROM SnazzySuppliers ss WHERE ss.unique_costs > 3)
ORDER BY sales_rank
LIMIT 10;
