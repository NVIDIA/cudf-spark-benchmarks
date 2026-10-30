WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_status
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
       OR c.c_mktsegment = 'BUILDING'
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) OVER (PARTITION BY l.l_orderkey) AS line_count,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_flag
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    c.balance_status,
    SUM(COALESCE(od.net_revenue, 0)) AS total_net_revenue,
    SUM(su.total_supplycost) AS total_supplycost,
    r.supplier_count,
    o.price_rank
FROM FilteredCustomers c
LEFT JOIN OrderLineDetails od ON c.c_custkey = od.l_orderkey
LEFT JOIN SupplierAggregates su ON c.c_custkey = su.ps_suppkey
JOIN NationRegion r ON c.c_custkey = r.n_nationkey
JOIN RankedOrders o ON c.c_custkey = o.o_orderkey AND o.price_rank <= 5
WHERE (c.c_acctbal BETWEEN 500 AND 5000 OR c.c_name LIKE '%Inc%')
GROUP BY c.c_name, c.balance_status, r.supplier_count, o.price_rank
HAVING SUM(od.net_revenue) > 1000 OR MAX(su.total_supplycost) IS NULL;
