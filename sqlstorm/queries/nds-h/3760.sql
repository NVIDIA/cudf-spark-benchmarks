
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerNations AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 1000.00
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.total_supply_cost, 0) AS supply_cost,
    c.n_name AS customer_nation,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
FROM part p
LEFT JOIN SupplierPartCosts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN RankedOrders o ON li.l_orderkey = o.o_orderkey AND o.order_rank <= 10
LEFT JOIN CustomerNations c ON c.c_custkey = li.l_suppkey
WHERE p.p_retailprice > 20.00 AND 
      (sp.total_supply_cost IS NOT NULL OR c.n_name IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, c.n_name, sp.total_supply_cost
HAVING SUM(li.l_quantity) > 100
ORDER BY total_revenue DESC;
