WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    COALESCE(ss.supplier_count, 0) AS total_suppliers,
    COALESCE(ss.total_supply_cost, 0.00) AS total_supply_cost,
    COUNT(DISTINCT ro.o_orderkey) AS total_ranked_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerStats cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN RankedOrders ro ON cs.total_spent > 1000 AND ro.rank_order <= 10
GROUP BY r.r_name, cs.total_spent, ss.supplier_count, ss.total_supply_cost
ORDER BY r.r_name;