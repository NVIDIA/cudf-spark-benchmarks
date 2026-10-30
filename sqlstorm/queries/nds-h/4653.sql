WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
), SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
), HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value_amount
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    COALESCE(sc.total_supplycost, 0) AS average_supplycost,
    COALESCE(fc.order_count, 0) AS customer_order_count,
    hvl.high_value_amount
FROM RankedOrders o
LEFT JOIN SupplierCosts sc ON o.o_orderkey = sc.ps_partkey
LEFT JOIN FrequentCustomers fc ON o.o_orderkey = fc.c_custkey
LEFT JOIN HighValueLineItems hvl ON o.o_orderkey = hvl.l_orderkey
WHERE o.rn <= 10 
AND (o.o_orderstatus = 'F' OR o.o_totalprice > 500)
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;