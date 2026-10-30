WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS SupplyValue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        SUM(l.l_quantity) AS TotalQuantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
EnhancedAnalysis AS (
    SELECT 
        c.c_name,
        SUM(ol.TotalRevenue) AS RevenueFromOrders,
        SUM(sp.SupplyValue) AS TotalSupplyValue
    FROM CustomerOrders co
    JOIN OrderLineItems ol ON co.o_orderkey = ol.o_orderkey
    JOIN SupplierParts sp ON ol.o_orderkey = sp.s_suppkey
    JOIN customer c ON co.c_custkey = c.c_custkey
    GROUP BY c.c_name
)
SELECT 
    e.c_name,
    e.RevenueFromOrders,
    e.TotalSupplyValue,
    (e.RevenueFromOrders - e.TotalSupplyValue) AS ProfitMargin
FROM EnhancedAnalysis e
WHERE e.RevenueFromOrders > e.TotalSupplyValue
ORDER BY ProfitMargin DESC
LIMIT 10;
