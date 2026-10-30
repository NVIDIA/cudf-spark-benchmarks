WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
JoinedDetails AS (
    SELECT sd.s_suppkey, sd.s_name, cd.c_custkey, cd.c_name,
           nd.n_name AS nation_name, sd.total_supply_cost, cd.total_orders
    FROM SupplierDetails sd
    JOIN CustomerDetails cd ON sd.s_nationkey = cd.c_nationkey
    JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
)
SELECT nation_name, COUNT(DISTINCT s_suppkey) AS supplier_count, AVG(total_supply_cost) AS avg_supply_cost,
       SUM(total_orders) AS total_orders_sum
FROM JoinedDetails
GROUP BY nation_name
ORDER BY nation_name;
