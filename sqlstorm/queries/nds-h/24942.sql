WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
),
CustomerSums AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spend,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        MIN(ps.ps_supplycost) AS min_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spend,
        RANK() OVER (ORDER BY cs.total_spend DESC) AS customer_rank
    FROM CustomerSums cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spend,
    sd.s_suppkey,
    sd.s_name,
    sd.total_supply_value,
    sd.min_supply_cost,
    sd.max_supply_cost,
    (SELECT COUNT(DISTINCT l.l_orderkey)
     FROM lineitem l 
     WHERE l.l_suppkey = sd.s_suppkey 
     AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31') AS orders_fulfilled
FROM TopCustomers tc
LEFT JOIN SupplierDetails sd ON tc.customer_rank = 1
WHERE tc.total_spend > 
      (SELECT AVG(total_spend) FROM CustomerSums)
  AND sd.total_supply_value IS NOT NULL
ORDER BY tc.total_spend DESC, sd.total_supply_value ASC
LIMIT 10;