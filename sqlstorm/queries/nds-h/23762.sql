WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
FilterCust AS (
    SELECT 
        c.c_custkey,
        cp.total_spent,
        cp.order_count
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_custkey = c.c_custkey
    WHERE cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
      AND cp.order_count < (SELECT COUNT(DISTINCT o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'O')
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ss.available_parts) AS total_available_parts,
    AVG(cp.total_spent) AS avg_customer_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN FilterCust cp ON s.s_suppkey = cp.c_custkey
GROUP BY r.r_name
HAVING SUM(ss.total_cost) IS NOT NULL
   OR EXISTS (SELECT 1 FROM FilterCust fc WHERE fc.total_spent > 10000)
ORDER BY r.r_name;