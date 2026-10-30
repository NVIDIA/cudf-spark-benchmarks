
WITH RankedOrders AS (
    SELECT 
        o_custkey,
        o_orderkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
    WHERE o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT ps_partkey) AS part_count,
        AVG(ps_supplycost) AS avg_supply_cost,
        MAX(s_acctbal) AS max_account_balance
    FROM supplier 
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_nationkey
),
RegionalDemand AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' AND l.l_returnflag = 'N'
    GROUP BY n.n_nationkey, n.n_name
),
FinalReport AS (
    SELECT 
        r.r_name,
        COALESCE(rd.total_revenue, 0) AS total_revenue,
        COALESCE(ss.part_count, 0) AS total_parts,
        COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
        COALESCE(ss.max_account_balance, 0) AS max_account_balance,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    LEFT JOIN RegionalDemand rd ON r.r_regionkey = rd.n_nationkey
    LEFT JOIN SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN RankedOrders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = r.r_regionkey
    )
    GROUP BY r.r_name, rd.total_revenue, ss.part_count, ss.avg_supply_cost, ss.max_account_balance
)
SELECT 
    r_name,
    total_revenue,
    total_parts,
    avg_supply_cost,
    max_account_balance,
    total_orders,
    CASE 
        WHEN total_revenue > 1000000 THEN 'High'
        WHEN total_revenue = 0 THEN 'Zero'
        ELSE 'Medium'
    END AS revenue_category
FROM FinalReport
ORDER BY total_revenue DESC NULLS LAST;
