WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_nationkey
    FROM RankedOrders r
    WHERE r.rank_by_price <= 5
),
AggregateSupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
CompetitiveAnalysis AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
        SUM(a.total_supply_cost) AS total_supplier_cost
    FROM HighValueOrders h
    JOIN nation n ON h.c_nationkey = n.n_nationkey
    LEFT JOIN AggregateSupplierCosts a ON h.o_orderkey = a.ps_suppkey
    GROUP BY n.n_name
)
SELECT 
    ca.nation_name,
    ca.high_value_order_count,
    ca.total_supplier_cost,
    RANK() OVER (ORDER BY ca.high_value_order_count DESC) AS rank_by_orders
FROM CompetitiveAnalysis ca
ORDER BY ca.high_value_order_count DESC, ca.total_supplier_cost ASC;