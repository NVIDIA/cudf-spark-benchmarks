
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
FilteredLineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_with_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
DistinctNations AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    WHERE n.n_comment NOT LIKE '%error%'
),
FinalResults AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(o.o_totalprice) AS avg_order_price,
        SUM(COALESCE(sd.part_count, 0)) AS total_part_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
    LEFT JOIN SupplierDetails sd ON sd.s_name = 'Supplier Y'
    WHERE r.r_name IN (SELECT n_name FROM DistinctNations)
    GROUP BY r.r_name
)
SELECT * 
FROM FinalResults
WHERE avg_order_price > (
    SELECT AVG(o.o_totalprice) FROM RankedOrders o
)
ORDER BY customer_count DESC, total_part_count ASC;
