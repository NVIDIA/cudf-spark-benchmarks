
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
OrderDetails AS (
    SELECT 
        lo.o_orderkey,
        lo.o_orderdate,
        lo.o_totalprice,
        s.s_name,
        ps.total_avail,
        ps.avg_cost,
        hlo.total_sales,
        lo.rn
    FROM RankedOrders lo
    LEFT JOIN lineitem li ON lo.o_orderkey = li.l_orderkey
    LEFT JOIN SupplierStats ps ON li.l_partkey = ps.ps_partkey
    LEFT JOIN HighValueOrders hlo ON lo.o_orderkey = hlo.l_orderkey
    LEFT JOIN supplier s ON li.l_suppkey = s.s_suppkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    COALESCE(od.total_sales, 0) AS total_sales,
    od.o_totalprice,
    od.s_name,
    od.total_avail,
    CASE 
        WHEN od.total_avail IS NULL THEN 'No Supplies Available'
        ELSE 'Supplies Available'
    END AS supply_status
FROM OrderDetails od
WHERE od.rn <= 5
ORDER BY od.o_orderdate DESC, od.o_totalprice DESC;
