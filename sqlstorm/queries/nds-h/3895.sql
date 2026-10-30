WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        o_totalprice,
        RANK() OVER (PARTITION BY o_orderdate ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
    WHERE o_orderdate > '1996-01-01'
),
SupplierTotals AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost) AS total_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        pt.total_supplycost
    FROM part p
    JOIN SupplierTotals pt ON p.p_partkey = pt.ps_partkey
    WHERE pt.total_supplycost > 1000.00
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice,
        (l.l_discount * l.l_extendedprice) AS discount_value,
        l.l_returnflag,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS order_line
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    R.o_totalprice,
    P.p_name,
    P.total_supplycost,
    O.c_name,
    O.discount_value,
    (CASE 
        WHEN O.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END) AS return_status
FROM RankedOrders R
LEFT JOIN HighValueParts P ON R.o_orderkey = P.p_partkey
LEFT JOIN SuspiciousOrders O ON R.o_orderkey = O.o_orderkey
WHERE R.price_rank = 1
  AND (R.o_totalprice > 500.00 OR O.discount_value > 100.00)
ORDER BY R.o_orderdate DESC, R.o_totalprice DESC;