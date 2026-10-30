WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn_status,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate ASC) AS dr_orderdate
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
      AND o.o_totalprice IS NOT NULL
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        MAX(l.l_shipdate) AS last_shipdate,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SuppliersWithHighVolume AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 500 AND s.s_comment NOT LIKE '%unreliable%'
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 1000
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    CASE 
        WHEN ro.o_orderstatus = 'F' THEN 'Finalized'
        WHEN ro.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status,
    COALESCE(lli.total_revenue, 0) AS total_revenue,
    COALESCE(lli.item_count, 0) AS item_count,
    SW.total_avail_qty,
    ro.dr_orderdate,
    CASE 
        WHEN SW.total_avail_qty IS NULL THEN 'No Supplier Available'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM RankedOrders ro
LEFT JOIN FilteredLineItems lli ON ro.o_orderkey = lli.l_orderkey
LEFT JOIN SuppliersWithHighVolume SW ON SW.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps LIMIT 1)
WHERE ro.rn_status <= 10
ORDER BY ro.o_orderdate DESC, ro.o_orderkey;