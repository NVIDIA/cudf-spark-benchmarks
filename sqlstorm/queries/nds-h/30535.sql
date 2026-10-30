
WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.avg_acct_balance,
    p.p_name,
    p.total_value,
    COALESCE(so.total_orders, 0) AS total_orders_last_year
FROM 
    NationSummary ns
LEFT JOIN 
    HighValueParts p ON ns.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rank <= 5))
LEFT JOIN 
    (SELECT 
         ro.o_custkey,
         COUNT(ro.o_orderkey) AS total_orders
     FROM 
         RecentOrders ro
     WHERE 
         ro.recent_order_rank <= 3
     GROUP BY 
         ro.o_custkey) so ON ns.n_nationkey = so.o_custkey
WHERE 
    ns.supplier_count IS NOT NULL
ORDER BY 
    ns.avg_acct_balance DESC, p.total_value DESC
LIMIT 10;
