WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        COUNT(l.l_orderkey) FILTER (WHERE l.l_discount > 0) AS discounted_orders
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
), 
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 0 THEN 'Negative Balance'
            ELSE 'Positive Balance'
        END AS balance_status
    FROM 
        customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cr.c_name,
    cr.nation_name,
    SUM(os.o_totalprice) AS total_spent,
    AVG(ss.total_supplycost) AS avg_supplycost,
    MAX(os.o_orderdate) AS last_order_date,
    COUNT(CASE WHEN os.order_rank = 1 THEN 1 END) AS recent_orders,
    COUNT(DISTINCT ss.total_orders) AS total_distinct_suppliers
FROM 
    CustomerRegion cr
JOIN RankedOrders os ON cr.c_custkey = os.o_orderkey
JOIN SupplierStats ss ON ss.total_orders > 0
GROUP BY 
    cr.c_name,
    cr.nation_name
HAVING 
    SUM(os.o_totalprice) > 1000
    AND COUNT(ss.discounted_orders) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;