WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate = o.o_orderdate
    )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS balance_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartSupplierMetrics AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice) > 10000
),
RegionalSummary AS (
    SELECT 
        r.r_name,
        SUM(COALESCE(hvl.total_revenue, 0)) AS total_revenue,
        COUNT(DISTINCT CASE WHEN hvl.unique_parts > 5 THEN hvl.l_orderkey END) AS high_value_orders
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN HighValueLines hvl ON o.o_orderkey = hvl.l_orderkey
    GROUP BY r.r_name
)
SELECT 
    rsm.r_name,
    rsm.total_revenue,
    rsm.high_value_orders,
    sd.s_name,
    rd.r_value,
    psm.total_avail_qty,
    CASE 
        WHEN rsm.total_revenue IS NULL THEN 'No Revenue Data' 
        ELSE CAST(rsm.total_revenue AS STRING)
    END AS revenue_amount,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderdate = cast('1998-10-01' as date)) AS current_day_orders
FROM RegionalSummary rsm
JOIN SupplierDetails sd ON sd.balance_rank <= 10
JOIN PartSupplierMetrics psm ON psm.ps_partkey = (
    SELECT MIN(ps_partkey) FROM partsupp 
    WHERE ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
)
LEFT JOIN (
    SELECT 1 AS r_value UNION SELECT 2 UNION SELECT NULL UNION SELECT 3
) AS rd ON rsm.high_value_orders > 0
ORDER BY rsm.total_revenue DESC NULLS LAST;