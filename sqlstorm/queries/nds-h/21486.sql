
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_order
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
EligibleSuppliers AS (
    SELECT r.r_regionkey, r.r_name, ns.n_name AS nation_name, rs.s_suppkey, 
           rs.s_name, rs.s_acctbal
    FROM region r
    LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey
    WHERE rs.rank_order <= 5 OR rs.rank_order IS NULL
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT ed.r_name, ed.nation_name, cd.c_mktsegment, 
           SUM(os.total_price) AS total_revenue,
           COUNT(DISTINCT cd.c_custkey) AS unique_customers
    FROM EligibleSuppliers ed
    JOIN CustomerDetails cd ON ed.s_suppkey = cd.c_custkey
    LEFT JOIN OrderStats os ON cd.order_count > 0
    GROUP BY ed.r_name, ed.nation_name, cd.c_mktsegment
)
SELECT r.r_name, r.nation_name, r.c_mktsegment,
       COALESCE(r.total_revenue, 0) AS total_revenue,
       COALESCE(r.unique_customers, 0) AS unique_customers,
       CASE
           WHEN r.total_revenue = 0 AND r.unique_customers = 0 THEN 'No Data'
           ELSE 'Data Available'
       END AS data_availability
FROM FinalReport r
ORDER BY r.r_name, r.nation_name, r.c_mktsegment;
