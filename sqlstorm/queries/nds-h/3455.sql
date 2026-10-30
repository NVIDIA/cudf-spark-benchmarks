
WITH SupplierData AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderData AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.total_price) DESC) AS rank
    FROM customer c
    JOIN OrderData o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT rc.c_custkey) AS total_ranked_customers,
    SUM(sd.total_supply_cost) AS total_supply_cost
FROM RankedCustomers rc
JOIN nation n ON rc.c_nationkey = n.n_nationkey
LEFT JOIN SupplierData sd ON n.n_nationkey = sd.s_nationkey
WHERE rc.rank <= 5
GROUP BY n.n_name
ORDER BY total_supply_cost DESC;
