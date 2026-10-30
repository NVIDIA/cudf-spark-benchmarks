WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    s.s_name AS supplier_name,
    sd.total_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
FROM RankedOrders o
LEFT JOIN CustomerOrders c ON o.o_orderkey = c.c_custkey
LEFT JOIN SupplierDetails sd ON o.o_orderkey = sd.s_suppkey
LEFT JOIN supplier s ON sd.s_suppkey = s.s_suppkey
WHERE sd.total_cost IS NOT NULL 
AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY customer_name, o.o_orderdate DESC, order_rank
LIMIT 100;