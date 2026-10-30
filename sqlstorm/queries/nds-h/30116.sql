WITH RecursiveOrder AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
RankedRevenue AS (
    SELECT o_orderkey, o_orderdate, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RecursiveOrder
),
TopRevenueOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.total_revenue,
           COALESCE(c.c_name, 'Unknown') AS customer_name
    FROM RankedRevenue r
    LEFT JOIN orders o ON r.o_orderkey = o.o_orderkey
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE revenue_rank <= 10
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
JoinedResults AS (
    SELECT t.o_orderkey, t.o_orderdate, t.customer_name,
           p.p_name, s.s_name, s.s_acctbal, sp.total_availqty, sp.total_supplycost
    FROM TopRevenueOrders t
    JOIN lineitem l ON t.o_orderkey = l.l_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey AND s.s_suppkey = sp.ps_suppkey
)
SELECT j.o_orderkey, j.o_orderdate, 
       j.customer_name, j.p_name, j.s_name,
       COALESCE(j.total_availqty, 0) AS available_quantity,
       ROUND(j.total_supplycost, 2) AS supply_cost,
       (CASE 
            WHEN j.s_acctbal IS NULL THEN 'No account balance'
            ELSE CONCAT('Account Balance: ', j.s_acctbal)
        END) AS account_info
FROM JoinedResults j
WHERE j.total_availqty IS NOT NULL
ORDER BY j.o_orderdate DESC, j.total_supplycost DESC;
