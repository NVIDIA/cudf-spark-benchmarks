WITH FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name, r.r_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal > 10000 AND r.r_name = 'ASIA'
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spending
    FROM orders o
    JOIN FilteredCustomers fc ON o.o_custkey = fc.c_custkey
    GROUP BY o.o_custkey
),
LineItemDetails AS (
    SELECT ls.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders ls ON l.l_orderkey = ls.o_orderkey
    JOIN FilteredCustomers fc ON ls.o_custkey = fc.c_custkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY ls.o_custkey
)
SELECT fc.c_name, 
       os.total_orders, 
       os.total_spending, 
       ld.total_value, 
       ld.total_quantity,
       (os.total_spending + COALESCE(ld.total_value, 0)) AS grand_total
FROM FilteredCustomers fc
LEFT JOIN OrderSummary os ON fc.c_custkey = os.o_custkey
LEFT JOIN LineItemDetails ld ON fc.c_custkey = ld.o_custkey
ORDER BY grand_total DESC
LIMIT 10;