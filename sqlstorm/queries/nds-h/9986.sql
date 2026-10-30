WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
),
AggregatedData AS (
    SELECT 
        sp.s_suppkey,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue,
        COUNT(DISTINCT co.o_orderkey) AS order_count,
        SUM(sp.ps_availqty) AS total_avail_qty
    FROM SupplierParts sp
    JOIN OrderLineItems ol ON sp.p_partkey = ol.l_partkey
    JOIN CustomerOrders co ON ol.l_orderkey = co.o_orderkey
    GROUP BY sp.s_suppkey
)
SELECT 
    s.s_name, 
    ad.revenue, 
    ad.order_count, 
    ad.total_avail_qty,
    RANK() OVER (ORDER BY ad.revenue DESC) as RevenueRank
FROM AggregatedData ad
JOIN supplier s ON ad.s_suppkey = s.s_suppkey
WHERE ad.revenue > 10000
ORDER BY ad.revenue DESC
LIMIT 10;