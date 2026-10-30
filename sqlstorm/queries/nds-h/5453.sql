WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
ProductDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, COALESCE(pd.total_available_qty, 0) AS total_avail_qty, COALESCE(pd.avg_supply_cost, 0) AS avg_supply_cost
    FROM part p
    LEFT JOIN PartSupplierDetails pd ON p.p_partkey = pd.ps_partkey
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(co.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT ns.n_name, COUNT(DISTINCT co.o_orderkey) AS number_of_orders, SUM(co.o_totalprice) AS total_sales,
       AVG(pd.p_retailprice) AS avg_part_retail_price, SUM(pd.total_avail_qty) AS total_available_parts,
       AVG(pd.avg_supply_cost) AS avg_supply_cost_per_part
FROM NationSales ns
JOIN CustomerOrders co ON ns.n_nationkey = co.o_orderkey
JOIN ProductDetails pd ON co.o_orderkey = pd.p_partkey
GROUP BY ns.n_name
ORDER BY total_sales DESC, number_of_orders DESC
LIMIT 10;
