WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
RecentOrders AS (
    SELECT * FROM RankedOrders WHERE order_rank <= 5
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 500.00
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
PartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    JOIN RecentOrders r ON l.l_orderkey = r.o_orderkey
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_revenue, 0) AS total_revenue,
    COALESCE(sa.total_available, 0) AS total_available,
    CASE 
        WHEN sa.total_available IS NULL THEN 'No Supply'
        WHEN COALESCE(ps.total_revenue, 0) = 0 THEN 'No Sales'
        ELSE 'Available'
    END AS supply_status
FROM part p
LEFT JOIN PartSales ps ON p.p_partkey = ps.l_partkey
LEFT JOIN SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY total_revenue DESC, total_available DESC;
