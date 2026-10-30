WITH HighValueSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier
    )
),
TopCustomers AS (
    SELECT c_custkey, c_name, SUM(o_totalprice) AS total_spent
    FROM customer
    JOIN orders ON customer.c_custkey = orders.o_custkey
    GROUP BY c_custkey, c_name
    HAVING SUM(o_totalprice) > 10000
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost, 
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemAnalysis AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY l.l_partkey
)
SELECT p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice,
       COALESCE(pas.total_supplycost, 0) AS total_supplycost,
       COALESCE(la.total_revenue, 0) AS total_revenue,
       tc.total_spent AS top_customer_spending
FROM part p
LEFT JOIN PartSupplierSummary pas ON p.p_partkey = pas.ps_partkey
LEFT JOIN LineItemAnalysis la ON p.p_partkey = la.l_partkey
LEFT JOIN TopCustomers tc ON tc.total_spent = (
    SELECT MAX(total_spent)
    FROM TopCustomers
)
WHERE p.p_retailprice > 50.00
ORDER BY total_revenue DESC, total_supplycost DESC
LIMIT 100;
